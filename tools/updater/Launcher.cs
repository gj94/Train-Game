using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace TrainGameUpdater {
    static class Launcher {
        static string Option(string[] args, string name, string fallback) {
            string value = args.FirstOrDefault(a => a.StartsWith(name + "="));
            return value == null ? fallback : value.Substring(name.Length + 1);
        }
        [STAThread] static int Main(string[] args) {
            string directory = Option(args, "--install-dir", AppDomain.CurrentDomain.BaseDirectory);
            string key;
            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("public-key.xml"))
            using (var reader = new StreamReader(stream)) key = reader.ReadToEnd();
            string config = Path.Combine(directory, "Update-server.txt");
            string address = Option(args, "--server", File.Exists(config) ? File.ReadAllText(config).Trim() : "http://192.168.8.183:8765/");
            if (args.Contains("--no-ui")) {
                try {
                    var core = new UpdateCore(directory, address, key, (text, percent) => Console.Error.WriteLine(text));
                    Console.WriteLine(new JavaScriptSerializer().Serialize(core.Update()));
                    if (!args.Contains("--update-only")) core.Play();
                    return 0;
                } catch (Exception error) { Console.Error.WriteLine(error.Message); return 1; }
            }
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new UpdateWindow(directory, address, key)); return 0;
        }
    }
    sealed class UpdateWindow : Form {
        string directory;
        readonly string key;
        readonly LinkLabel location = new LinkLabel();
        readonly TextBox address = new TextBox();
        readonly Label status = new Label();
        readonly ProgressBar bar = new ProgressBar();
        readonly Button update = new Button(), play = new Button();
        bool busy;
        DateTime lastReport = DateTime.MinValue;
        public UpdateWindow(string folder, string server, string publicKey) {
            directory = folder; key = publicKey;
            Text = "Train Game | Update & Play"; ClientSize = new Size(640, 378);
            FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen; Font = new Font("Segoe UI", 10);
            Controls.Add(new Label { Text = "Train Game", Font = new Font("Segoe UI", 23, FontStyle.Bold), Bounds = new Rectangle(26, 18, 560, 46) });
            Controls.Add(new Label { Text = "Keep this installation. Download and write only changed blocks.", Bounds = new Rectangle(28, 70, 586, 28) });
            location.Text = "Game folder (click to change): " + directory;
            location.AutoEllipsis = true; location.Bounds = new Rectangle(28, 108, 584, 28); Controls.Add(location);
            location.LinkClicked += delegate {
                using (var chooser = new FolderBrowserDialog { Description = "Select the existing folder containing TrainGame.exe and TrainGame.pck", SelectedPath = directory }) {
                    if (chooser.ShowDialog(this) == DialogResult.OK) { directory = chooser.SelectedPath; location.Text = "Game folder (click to change): " + directory; }
                }
            };
            Controls.Add(new Label { Text = "LAN update server", Bounds = new Rectangle(28, 150, 570, 23) });
            address.Text = server; address.Bounds = new Rectangle(28, 178, 584, 28); Controls.Add(address);
            status.Text = "Ready. Close the game before updating."; status.Bounds = new Rectangle(28, 220, 584, 45); Controls.Add(status);
            bar.Bounds = new Rectangle(28, 276, 584, 10); Controls.Add(bar);
            update.Text = "Update && Play"; update.Bounds = new Rectangle(28, 310, 278, 42); Controls.Add(update);
            play.Text = "Play installed (offline)"; play.Bounds = new Rectangle(320, 310, 292, 42); Controls.Add(play);
            update.Click += async delegate {
                if ((!File.Exists(Path.Combine(directory, "TrainGame.exe")) || !File.Exists(Path.Combine(directory, "TrainGame.pck"))) &&
                    MessageBox.Show(this, "This folder does not contain a complete Train Game installation. Installing here needs the full game download (about 2 GB).\n\nChoose No and use Game folder to select your existing installation for a small update. Install here anyway?", "Choose an installation", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
                SetBusy(true);
                try {
                    string url = address.Text.Trim();
                    var core = new UpdateCore(directory, url, key, Report);
                    // This is an editable convenience address, not the signature trust key.
                    string path = Path.Combine(directory, "Update-server.txt");
                    if ((File.Exists(path) && (File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0)) throw new IOException("Server configuration must not be a link.");
                    if (!File.Exists(path) || File.ReadAllText(path).Trim() != url) File.WriteAllText(path, url + Environment.NewLine);
                    await Task.Run(() => core.Update());
                    core.Play(); CloseAfterWork();
                } catch (Exception error) { ShowError(error); } finally { SetBusy(false); }
            };
            play.Click += delegate {
                try { Directory.CreateDirectory(Path.Combine(directory, ".train-update")); new UpdateCore(directory, address.Text.Trim(), key, null).Play(); Close(); }
                catch (Exception error) { ShowError(error); }
            };
            FormClosing += (sender, e) => { if (busy) { e.Cancel = true; status.Text = "Please let the update finish. Interrupted updates resume through this launcher."; } };
        }
        void SetBusy(bool value) { busy = value; update.Enabled = play.Enabled = address.Enabled = location.Enabled = !value; }
        void CloseAfterWork() { busy = false; Close(); }
        void Report(string message, int percent) {
            if (percent < 100 && (DateTime.UtcNow - lastReport).TotalMilliseconds < 120) return;
            lastReport = DateTime.UtcNow;
            BeginInvoke((Action)delegate { if (!IsDisposed) { status.Text = message; bar.Value = Math.Max(0, Math.Min(100, percent)); } });
        }
        void ShowError(Exception error) {
            status.Text = "Update not completed. Your saved journeys are untouched.";
            MessageBox.Show(this, error.Message + "\n\nClose any running Train Game before updating. If the server is asleep, Play installed works unless an update was already being applied. Reopen this launcher to resume.", "Train Game", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }
}
