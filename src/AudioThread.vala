namespace Strings.Audio {
    public class AudioThread {
        protected Device device;
        protected bool is_running;
        protected Thread<bool> thread;

        public AudioThread.from_device (Device device) {
            this.device = device;
            thread = new Thread<bool> ("audio-thread", start);
        }

        protected bool start () {
            is_running = true;
            //  Posix.printf ("Buffer size: %d\n", floor_power_two (4 * device.sample_rate));
            var signal = new Sample[floor_power_two (4 * device.sample_rate)];
            try {
                device.init ();
                while (is_running) {
                    device.record (signal);
                    //  var file = Posix.FILE.open ("test.txt", "w");
                    //  foreach (var sample in signal) {
                    //      file.printf("%d ", sample);
                    //  }
                    recognize_tone (signal);
                }
            } catch (Audio.DeviceError devErr) {
                stderr.printf ("%s\n", devErr.message); 
            } finally {
                is_running = false;
                device.close ();
            }
            return true;
        }

        private int floor_power_two (int n) {
            if (n != 0 && (n & (n - 1)) == 0) { return n; }
            // TODO: Optimize this
            return (int) Math.pow (2, Math.floor (Math.log (n) / Math.log (2)));
        }

        // TODO: Fix dis
        protected void recognize_tone (Sample[] signal) {
            Complex[] cpl_signal = new Complex[signal.length];
            var max_magn = 0.0;
            for (var i = 0; i < signal.length; i++) {
                cpl_signal[i].real = signal[i];
            }
            stdout.printf ("Signal length: %d\n", cpl_signal.length);
            fft (cpl_signal);
            var file = Posix.FILE.open ("test.txt", "w");
            foreach (var k in cpl_signal) {
                file.printf("%s ", k.to_string ());
            }
            var max_ind = 1;
            max_magn = cpl_signal[1].magn_squared ();
            for (var i = 2; i <= cpl_signal.length / 2; i++) {
                var i_magn = cpl_signal[i].magn_squared ();
                if (i_magn > max_magn) {
                    max_ind = i;
                    max_magn = i_magn;
                }
            }
            stdout.printf ("Max index: %d\n", max_ind);
            stdout.printf (
                "Frequency: %.2lf Hz\n",
                ((double) max_ind / cpl_signal.length) * device.sample_rate);
        }

        public void stop () {
            is_running = false;
            stdout.printf ("Done listening!\n");
        }
    }
}
