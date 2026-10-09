using System;
using System.IO;
using System.Web.Script.Serialization;
using TrainGameUpdater;

static class TestClient {
    static int Main(string[] args) {
        FileStream held = null;
        try {
            var core = new UpdateCore(args[0], args[1], File.ReadAllText(args[2]), null);
            int count = 0;
            string checkpoint = args.Length > 3 ? args[3] : "";
            core.Checkpoint = phase => { if (phase == checkpoint && ++count == 1) throw new Exception("Injected interruption: " + phase); };
            if (checkpoint == "locked") held = new FileStream(Path.Combine(args[0], "TrainGame.pck"), FileMode.Open, FileAccess.Read, FileShare.Read);
            if (checkpoint == "play") { core.Play(); throw new Exception("Unexpected play success"); }
            Console.WriteLine(new JavaScriptSerializer().Serialize(core.Update())); return 0;
        } catch (Exception error) { Console.Error.WriteLine(error.Message); return 1; }
        finally { if (held != null) held.Dispose(); }
    }
}
