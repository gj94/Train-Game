// .NET Framework 4.x: no runtime installer, Node, PowerShell policy or admin rights.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

namespace TrainGameUpdater {
    public sealed class Envelope { public string payload; public string signature; }
    public sealed class Catalogue {
        public int format; public int minimumLauncher; public int blockSize; public int sequence;
        public string version; public FileEntry[] files; public ArchiveEntry archive;
    }
    public sealed class ArchiveEntry { public long size; public string sha256; }
    public sealed class FileEntry {
        public string path; public long size; public string sha256; public string[] chunks;
        public int[] encodedSizes; public long payloadSize;
        [ScriptIgnore] public long[] payloadOffsets;
    }
    public sealed class UpdateResult { public string version; public long downloadedBytes; public long writtenBytes; public long reusedBytes; public string method; public long plannedDownloadBytes; }
    public sealed class UpdateCore {
        public const int BlockSize = 65536;
        public const int LauncherVersion = 3;
        readonly string root, state, key;
        readonly Uri server;
        readonly Action<string, int> progress;
        readonly JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = 16000000 };
        public Action<string> Checkpoint; // Failure injection used only by the test harness.
        public UpdateCore(string directory, string address, string publicKey, Action<string, int> report) {
            root = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar);
            state = Path.Combine(root, ".train-update");
            key = publicKey; progress = report ?? delegate { };
            server = new Uri(address.TrimEnd('/') + "/");
            if ((server.Scheme != "http" && server.Scheme != "https") || server.UserInfo != "" || server.Query != "" || server.Fragment != "" || server.AbsolutePath != "/")
                throw new InvalidDataException("Use the LAN server address, for example http://192.168.8.183:8765/");
            RejectLinks(root); RejectLinks(state);
        }
        static string Hash(byte[] data) { using (var h = SHA256.Create()) return Hex(h.ComputeHash(data)); }
        static string Hex(byte[] hash) { return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant(); }
        static void RejectLinks(string path) {
            for (var part = new DirectoryInfo(path); part != null; part = part.Parent) {
                if ((File.Exists(part.FullName) || Directory.Exists(part.FullName)) && (File.GetAttributes(part.FullName) & FileAttributes.ReparsePoint) != 0)
                    throw new IOException("Update paths must not be symlinks or junctions: " + part.FullName);
            }
        }
        string Target(string name) {
            if (String.IsNullOrEmpty(name) || name.Length > 220 || name.Contains('\\') || name.Contains(':') || name.StartsWith("/") || name.Any(c => c < 32))
                throw new InvalidDataException("Invalid update path.");
            var parts = name.Split('/');
            foreach (var part in parts) {
                if (!Regex.IsMatch(part, @"^[A-Za-z0-9_ .()\-]+$") || part == "." || part == ".." || part.EndsWith(".") || part.EndsWith(" ") ||
                    Regex.IsMatch(part, @"^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)", RegexOptions.IgnoreCase)) throw new InvalidDataException("Invalid update path: " + name);
            }
            var allowed = new[] { "TrainGame.exe", "TrainGame.pck", "README.txt", "BUILD.txt", "SHA256SUMS.txt", "ENGINE-LICENSES.txt", "ASSET-SOURCES.md", "MAP-DATA-LICENSE.md", "Benchmark.ps1", "Run Performance Benchmark.cmd" };
            if (!allowed.Contains(name) && !name.StartsWith("guides/") && !name.StartsWith("station-notices/") &&
                !Regex.IsMatch(name, @"^packs/(trains|scenery|audio|railway|route|resources)-[0-1][0-9a-f]\.pck$")) throw new InvalidDataException("Unmanaged update path: " + name);
            string result = Path.GetFullPath(Path.Combine(root, name.Replace('/', Path.DirectorySeparatorChar)));
            if (!result.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Path escapes installation.");
            RejectLinks(result); return result;
        }
        public Catalogue Verify(byte[] signed) {
            if (signed.Length > 16000000) throw new InvalidDataException("Update catalogue too large.");
            var envelope = json.Deserialize<Envelope>(Encoding.UTF8.GetString(signed));
            byte[] data = Convert.FromBase64String(envelope.payload), signature = Convert.FromBase64String(envelope.signature);
            using (var rsa = new RSACryptoServiceProvider()) {
                rsa.PersistKeyInCsp = false; rsa.FromXmlString(key);
                if (!rsa.VerifyData(data, CryptoConfig.MapNameToOID("SHA256"), signature)) throw new InvalidDataException("Update signature is invalid. No game files were changed.");
            }
            var manifest = json.Deserialize<Catalogue>(Encoding.UTF8.GetString(data));
            if ((manifest.format != 1 && manifest.format != 2) || manifest.minimumLauncher > LauncherVersion || (manifest.format == 2 && manifest.minimumLauncher < 3) || manifest.blockSize != BlockSize || manifest.sequence < 1 ||
                !Regex.IsMatch(manifest.version ?? "", @"^TrainGame-[A-Za-z0-9_-]+$") || manifest.files == null || manifest.files.Length > 2000)
                throw new InvalidDataException("Unsupported update catalogue. Download the latest launcher.");
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            long total = 0;
            foreach (var file in manifest.files) {
                Target(file.path);
                if (!names.Add(file.path) || file.size < 0 || file.size > 16000000000L || !Regex.IsMatch(file.sha256 ?? "", "^[a-f0-9]{64}$") ||
                    file.chunks == null || file.chunks.LongLength != (file.size + BlockSize - 1) / BlockSize || file.chunks.Any(h => !Regex.IsMatch(h ?? "", "^[a-f0-9]{64}$")))
                    throw new InvalidDataException("Invalid file in update catalogue.");
                total += file.size;
                if (manifest.format == 1) file.encodedSizes = null;
                if (manifest.format == 2) {
                    if (file.encodedSizes == null || file.encodedSizes.Length != file.chunks.Length)
                        throw new InvalidDataException("Invalid compressed block index.");
                    file.payloadOffsets = new long[file.chunks.Length];
                    long payload = 0;
                    for (int i = 0; i < file.chunks.Length; i++) {
                        int length = (int)Math.Min(BlockSize, file.size - (long)i * BlockSize), encoded = file.encodedSizes[i];
                        if (encoded == 0 || encoded > length || encoded < -length || (encoded < 0 && encoded != -length))
                            throw new InvalidDataException("Invalid compressed block length.");
                        file.payloadOffsets[i] = payload; payload += Math.Abs(encoded);
                    }
                    if (file.payloadSize != payload) throw new InvalidDataException("Invalid compressed payload size.");
                }
            }
            if (total > 32000000000L || !names.Contains("TrainGame.exe") || !names.Contains("TrainGame.pck")) throw new InvalidDataException("Incomplete or oversized game update.");
            if (manifest.archive != null && (manifest.format != 2 || manifest.archive.size < 1 || manifest.archive.size > 34000000000L ||
                !Regex.IsMatch(manifest.archive.sha256 ?? "", "^[a-f0-9]{64}$"))) throw new InvalidDataException("Invalid full archive.");
            return manifest;
        }
        byte[] Fetch(string path, long offset, int count, long total) {
            var request = (HttpWebRequest)WebRequest.Create(new Uri(server, path));
            request.AllowAutoRedirect = false; request.Proxy = null;
            request.Timeout = 15000; request.ReadWriteTimeout = 15000;
            if (offset >= 0) request.AddRange(offset, offset + count - 1);
            using (var response = (HttpWebResponse)request.GetResponse()) {
                if (offset >= 0 && (response.StatusCode != HttpStatusCode.PartialContent || response.Headers["Content-Range"] != String.Format("bytes {0}-{1}/{2}", offset, offset + count - 1, total)))
                    throw new InvalidDataException("Server did not return the requested update blocks.");
                if (offset < 0 && response.StatusCode != HttpStatusCode.OK) throw new InvalidDataException("Update server unavailable.");
                using (var input = response.GetResponseStream()) using (var output = new MemoryStream()) {
                    byte[] buffer = new byte[65536]; int read;
                    while ((read = input.Read(buffer, 0, buffer.Length)) != 0) {
                        if (output.Length + read > count) throw new InvalidDataException("Oversized server response.");
                        output.Write(buffer, 0, read);
                    }
                    if (offset >= 0 && output.Length != count) throw new InvalidDataException("Incomplete update block.");
                    return output.ToArray();
                }
            }
        }
        static byte[] ReadBlock(FileStream file, long position, int length) {
            if (file.Length < position + length) return null;
            file.Position = position; byte[] buffer = new byte[length]; int read = 0;
            while (read < length) { int n = file.Read(buffer, read, length - read); if (n == 0) return null; read += n; }
            return buffer;
        }
        static void DurableWrite(string path, byte[] data) {
            RejectLinks(path); RejectLinks(path + ".tmp");
            using (var file = new FileStream(path + ".tmp", FileMode.Create, FileAccess.Write, FileShare.None)) { file.Write(data, 0, data.Length); file.Flush(true); }
            if (File.Exists(path)) File.Replace(path + ".tmp", path, null); else File.Move(path + ".tmp", path);
        }
        string CachePath(string hash) { string path = Path.Combine(state, hash + ".block"); RejectLinks(path); return path; }
        bool Cached(string hash, int length) {
            string path = CachePath(hash);
            return File.Exists(path) && new FileInfo(path).Length == length && Hash(File.ReadAllBytes(path)) == hash;
        }
        void Signal(string name) { if (Checkpoint != null) Checkpoint(name); }
        public bool Pending { get { RejectLinks(Path.Combine(state, "pending.json")); return File.Exists(Path.Combine(state, "pending.json")); } }
        public UpdateResult Update() {
            Directory.CreateDirectory(state);
            RejectLinks(Path.Combine(state, "lock"));
            using (var updateLock = new FileStream(Path.Combine(state, "lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None)) {
                // A committed plan always finishes before querying a newer version, even offline.
                if (Pending) {
                    progress("Finishing the interrupted update...", 0);
                    return Apply(File.ReadAllBytes(Path.Combine(state, "pending.json")), true);
                }
                progress("Checking the LAN server...", 0);
                byte[] signed = Fetch("updates/latest.json", -1, 16000000, 0);
                return Apply(signed, false);
            }
        }
        sealed class Work { public FileEntry file; public int index; public int length; }
        int TransferSize(Work item) { return item.file.encodedSizes == null ? item.length : Math.Abs(item.file.encodedSizes[item.index]); }
        string ArchivePath(Catalogue manifest) {
            string path = Path.Combine(state, manifest.archive.sha256 + ".zip"); RejectLinks(path); return path;
        }
        // Download to disk with bounded memory, exact range checks and restart
        // support. Never extract arbitrary archive paths into the installation.
        void PrepareArchive(Catalogue manifest, List<Work> needed, UpdateResult result) {
            string path = ArchivePath(manifest), partial = path + ".partial"; RejectLinks(partial);
            if (!File.Exists(path)) {
                using (var output = new FileStream(partial, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None)) {
                    if (output.Length > manifest.archive.size) output.SetLength(0);
                    while (output.Length < manifest.archive.size) {
                        long offset = output.Length;
                        int count = (int)Math.Min(4 * 1024 * 1024, manifest.archive.size - offset);
                        var bytes = Fetch(manifest.version + ".zip", offset, count, manifest.archive.size);
                        output.Position = offset; output.Write(bytes, 0, bytes.Length); output.Flush(true);
                        result.downloadedBytes += bytes.Length;
                        progress(String.Format("Downloading smaller full archive: {0:F1} / {1:F1} MiB", output.Length / 1048576.0, manifest.archive.size / 1048576.0),
                            25 + (int)(output.Length * 30 / manifest.archive.size));
                        Signal("archive-download");
                    }
                }
                bool valid;
                using (var input = File.OpenRead(partial))
                using (var sha = SHA256.Create()) valid = Hex(sha.ComputeHash(input)) == manifest.archive.sha256;
                if (!valid) {
                    File.Delete(partial); throw new InvalidDataException("Full archive failed verification. Installed files are unchanged.");
                }
                File.Move(partial, path);
            }
            using (var input = File.OpenRead(path)) {
                using (var sha = SHA256.Create()) if (input.Length != manifest.archive.size || Hex(sha.ComputeHash(input)) != manifest.archive.sha256) {
                    throw new InvalidDataException("Cached archive is damaged. Remove " + path + " and retry.");
                }
                input.Position = 0;
                using (var zip = new ZipArchive(input, ZipArchiveMode.Read)) {
                    foreach (var group in needed.GroupBy(w => w.file.path)) {
                        var expected = group.First().file;
                        string entryName = manifest.version + "/" + expected.path;
                        // Framework may expose DOS-created ZIP names with backslashes.
                        // Match only signed managed paths and reject canonical aliases.
                        var entries = zip.Entries.Where(e => e.FullName.Replace('\\', '/') == entryName).ToArray();
                        if (entries.Length != 1 || entries[0].Length != expected.size) throw new InvalidDataException("Missing, duplicate or wrong-sized archive entry: " + expected.path);
                        var wanted = new HashSet<int>(group.Select(w => w.index));
                        using (var source = entries[0].Open()) {
                            for (int i = 0; i < expected.chunks.Length; i++) {
                                int length = (int)Math.Min(BlockSize, expected.size - (long)i * BlockSize);
                                byte[] data = new byte[length]; int n = 0;
                                while (n < length) { int read = source.Read(data, n, length - n); if (read == 0) throw new InvalidDataException("Truncated archive entry."); n += read; }
                                if (!wanted.Contains(i)) continue;
                                if (Hash(data) != expected.chunks[i]) throw new InvalidDataException("Archive block failed verification.");
                                if (!Cached(expected.chunks[i], length)) DurableWrite(CachePath(expected.chunks[i]), data);
                                Signal("download");
                            }
                            if (source.ReadByte() != -1) throw new InvalidDataException("Oversized archive entry.");
                        }
                    }
                }
            }
        }
        UpdateResult Apply(byte[] signed, bool recovery) {
            var manifest = Verify(signed);
            string installedPath = Path.Combine(state, "installed.json"); RejectLinks(installedPath);
            if (File.Exists(installedPath)) {
                var installed = Verify(File.ReadAllBytes(installedPath));
                if (manifest.sequence < installed.sequence || (manifest.sequence == installed.sequence && manifest.version != installed.version)) throw new InvalidDataException("Refusing an older update catalogue.");
            }
            var handles = new Dictionary<string, FileStream>();
            var work = new List<Work>();
            var result = new UpdateResult { version = manifest.version };
            bool resize = false;
            try {
                // All files are locked before comparing, downloading or changing any existing bytes.
                foreach (var file in manifest.files) {
                    string path = Target(file.path);
                    if (File.Exists(path)) handles.Add(file.path, new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.None));
                }
                long scanned = 0, total = manifest.files.Sum(f => f.size);
                foreach (var file in manifest.files) {
                    FileStream handle; handles.TryGetValue(file.path, out handle);
                    resize |= handle == null || handle.Length != file.size;
                    for (int i = 0; i < file.chunks.Length; i++) {
                        int length = (int)Math.Min(BlockSize, file.size - (long)i * BlockSize);
                        var data = handle == null ? null : ReadBlock(handle, (long)i * BlockSize, length);
                        if (data == null || Hash(data) != file.chunks[i]) work.Add(new Work { file = file, index = i, length = length });
                        else result.reusedBytes += length;
                        scanned += length;
                    }
                    progress("Checking installed files (reading only): " + file.path, (int)(scanned * 25 / Math.Max(1, total)));
                }
                if (work.Count == 0 && !resize && !recovery) {
                    if (!File.Exists(installedPath) || !File.ReadAllBytes(installedPath).SequenceEqual(signed)) DurableWrite(installedPath, signed);
                    progress("Already up to date. No game data downloaded or rewritten.", 100); return result;
                }
                long changed = work.Sum(w => (long)w.length), downloaded = 0;
                // Deduplicate once, then choose the smallest encoded representation.
                var needed = work.GroupBy(w => w.file.chunks[w.index])
                    .Select(g => g.OrderBy(TransferSize).First()).Where(w => !Cached(w.file.chunks[w.index], w.length)).ToList();
                long compressedBytes = needed.Sum(w => (long)TransferSize(w));
                long archiveBytes = manifest.archive == null ? Int64.MaxValue : manifest.archive.size;
                if (manifest.archive != null) {
                    string archive = ArchivePath(manifest), partial = archive + ".partial"; RejectLinks(partial);
                    if (File.Exists(archive)) {
                        bool valid;
                        using (var input = File.OpenRead(archive))
                        using (var sha = SHA256.Create()) valid = input.Length == manifest.archive.size && Hex(sha.ComputeHash(input)) == manifest.archive.sha256;
                        if (valid) archiveBytes = 0;
                        else File.Delete(archive); // Cache only; never an installed game file.
                    }
                    if (archiveBytes > 0 && File.Exists(partial) && new FileInfo(partial).Length <= archiveBytes) archiveBytes -= new FileInfo(partial).Length;
                }
                bool useArchive = needed.Count > 0 && archiveBytes < compressedBytes;
                result.method = useArchive ? "full-archive" : manifest.format == 2 ? "compressed-blocks" : "legacy-blocks";
                result.plannedDownloadBytes = useArchive ? archiveBytes : compressedBytes;
                long space = needed.Sum(w => (long)w.length) + (useArchive ? archiveBytes : 0) +
                    manifest.files.Sum(f => Math.Max(0, f.size - (handles.ContainsKey(f.path) ? handles[f.path].Length : 0))) + signed.Length * 3L + 1048576;
                if (new DriveInfo(Path.GetPathRoot(root)).AvailableFreeSpace < space) throw new IOException("Not enough free space for changed blocks. Free " + (space / 1048576 + 1) + " MiB and retry.");
                progress(String.Format("{0}: {1:F1} MiB to download; keeping {2:F1} MiB installed.", useArchive ? "Full archive is smaller" : "Changed blocks are smaller", result.plannedDownloadBytes / 1048576.0, result.reusedBytes / 1048576.0), 25);
                if (useArchive) PrepareArchive(manifest, needed, result);
                else foreach (var item in needed) {
                    string hash = item.file.chunks[item.index];
                    if (!Cached(hash, item.length)) {
                        string name = String.Join("/", item.file.path.Split('/').Select(Uri.EscapeDataString));
                        byte[] data;
                        if (manifest.format == 2) {
                            var encoded = Fetch("update-payloads/" + manifest.version + "/" + name + ".blocks",
                                item.file.payloadOffsets[item.index], TransferSize(item), item.file.payloadSize);
                            result.downloadedBytes += encoded.Length;
                            if (item.file.encodedSizes[item.index] < 0) data = encoded;
                            else using (var source = new GZipStream(new MemoryStream(encoded), CompressionMode.Decompress)) {
                                data = new byte[item.length]; int n = 0;
                                while (n < data.Length) { int read = source.Read(data, n, data.Length - n); if (read == 0) throw new InvalidDataException("Truncated compressed block."); n += read; }
                                if (source.ReadByte() != -1) throw new InvalidDataException("Oversized compressed block.");
                            }
                        } else {
                            data = Fetch("update-files/" + manifest.version + "/" + name, (long)item.index * BlockSize, item.length, item.file.size);
                            result.downloadedBytes += data.Length;
                        }
                        if (Hash(data) != hash) throw new InvalidDataException("Downloaded block failed verification. Existing game files are unchanged until all blocks are ready.");
                        DurableWrite(CachePath(hash), data);
                    }
                    downloaded += TransferSize(item);
                    progress(String.Format("Downloading verified blocks: {0:F1} / {1:F1} MiB", downloaded / 1048576.0, compressedBytes / 1048576.0), 25 + (int)(downloaded * 40 / Math.Max(1, compressedBytes)));
                    Signal("download");
                }
                Signal("prepared");
                // Flush the complete authenticated plan before the first in-place write.
                // Cache blocks remain until all target files are flushed and verified.
                DurableWrite(Path.Combine(state, "pending.json"), signed); Signal("pending");
                foreach (var file in manifest.files) if (!handles.ContainsKey(file.path)) {
                    string path = Target(file.path); Directory.CreateDirectory(Path.GetDirectoryName(path));
                    handles.Add(file.path, new FileStream(path, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None));
                }
                long written = 0;
                foreach (var item in work) {
                    var data = File.ReadAllBytes(CachePath(item.file.chunks[item.index]));
                    if (data.Length != item.length || Hash(data) != item.file.chunks[item.index]) throw new InvalidDataException("Staged block damaged. Run Update again to repair it.");
                    var file = handles[item.file.path]; file.Position = (long)item.index * BlockSize; file.Write(data, 0, data.Length);
                    written += data.Length; result.writtenBytes += data.Length;
                    progress("Applying changed blocks. Reopen this launcher if interrupted.", 65 + (int)(written * 20 / Math.Max(1, changed)));
                    Signal("write");
                }
                foreach (var entry in manifest.files) {
                    var file = handles[entry.path];
                    if (file.Length != entry.size) file.SetLength(entry.size);
                    file.Flush(true); file.Position = 0;
                    using (var sha = SHA256.Create()) if (Hex(sha.ComputeHash(file)) != entry.sha256) throw new InvalidDataException("Final file verification failed: " + entry.path + ". Run Update again to repair it.");
                    Signal("verified");
                }
                progress("Verification complete.", 98);
                DurableWrite(installedPath, signed); Signal("installed");
                File.Delete(Path.Combine(state, "pending.json"));
                foreach (var path in Directory.GetFiles(state, "*.block")) {
                    if (Regex.IsMatch(Path.GetFileName(path), "^[a-f0-9]{64}\\.block$")) { RejectLinks(path); File.Delete(path); }
                }
                if (manifest.archive != null) {
                    string archive = ArchivePath(manifest), partial = archive + ".partial"; RejectLinks(partial);
                    if (File.Exists(archive)) File.Delete(archive);
                    if (File.Exists(partial)) File.Delete(partial);
                }
                progress(String.Format("Ready: downloaded {0:F1} MiB; wrote {1:F1} MiB of game data.", result.downloadedBytes / 1048576.0, result.writtenBytes / 1048576.0), 100);
                return result;
            } finally { foreach (var file in handles.Values) file.Dispose(); }
        }
        public void Play() {
            string exe = Target("TrainGame.exe"), pack = Target("TrainGame.pck");
            if (!File.Exists(exe) || !File.Exists(pack)) throw new IOException("Put this launcher beside your existing TrainGame.exe and TrainGame.pck, or click Update & Play to install.");
            RejectLinks(state); Directory.CreateDirectory(state); RejectLinks(Path.Combine(state, "lock"));
            using (var guard = new FileStream(Path.Combine(state, "lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None)) {
                if (Pending) throw new IOException("Finish the interrupted update first. Click Update & Play; verified blocks can be applied offline.");
                Process.Start(new ProcessStartInfo(exe) { WorkingDirectory = root, UseShellExecute = true });
            }
        }
    }
}
