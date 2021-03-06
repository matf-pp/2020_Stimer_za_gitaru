/*
 * Copyright (C) 2020 Dušan Gvozdenović. All rights reserved.
 *
 * This file is part of Strings.
 *
 * Strings is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Strings is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Strings. If not, see <https://www.gnu.org/licenses/>.
 */

using Alsa;

namespace Strings.Audio.Alsa {

     public class Device : Object, Audio.Device {
        public int frame_size { get; set; }
        public int sample_rate { get; set; }
        public int channels { get; set; }
        public string name { get; set; }

        protected PcmDevice device;
        protected PcmHardwareParams hw_params;
        protected PcmFormat format;

        public Device () {
            name = "default";
            sample_rate = 44100;
            channels = 2;
            frame_size = 1 << 12;
            format = PcmFormat.S16_LE;
        }

        public void init () throws DeviceError {
            int err;
            if ((err = PcmDevice.open (out device, name, PcmStream.CAPTURE)) < 0) {
                var msg = "ALSA Error (%d) - Cannot open audio device %s (%s).".printf (
                    err, name, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = PcmHardwareParams.malloc (out hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot allocate hardware parameter structure (%s)"
                    .printf (err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_any (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_access (hw_params, PcmAccess.RW_INTERLEAVED)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set access type (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_format (hw_params, format)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample format (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            //HACK: This works for some evil reason but it's not how it should work.
            int rate = sample_rate / 2;
            if ((err = device.hw_params_set_rate_near (hw_params, ref rate, 0)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample rate (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_channels (hw_params, channels)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set channel count (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set parameters (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
        }

        public void play (Sample[] buffer) throws DeviceError {
            stdout.printf("Not implemented yet!");
        }

        public void record (Sample[] buffer) throws DeviceError {
            debug ("Recording from ALSA device %s.", name);
            debug ("Sample type: Signed 16-bit little endian");
            debug ("Sample rate: %d", sample_rate);
            debug ("Channels: %d", channels);
            int err;
            if ((err = device.prepare ()) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
            var frame_width = channels * frame_size;
            var frames_whole = buffer.length / frame_width;
            var frames_end = frames_whole * frame_width;
            unowned uint8[] frame;
            for (var i = 0; i < frames_whole; i++) {
                frame = (uint8[]) buffer[(i * frame_width) : (i + 1) * frame_width];
                if ((err = (int) device.readi (frame, frame_size)) != frame_size) {
                    var msg = "ALSA Error (%d) - Read from audio interface failed (%s)".printf (
                        err, global::Alsa.strerror (err));
                    throw new DeviceError.RECORD_FAIL (msg);
                }
            }
            if (frames_end == buffer.length) { return; }
            frame = (uint8[]) buffer[frames_end : buffer.length];
            var rest_size = frame.length / (channels * sizeof (Sample));
            if ((err = (int) device.readi (frame, rest_size)) != rest_size) {
                var msg = "ALSA Error (%d) - Read from audio interface failed (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.RECORD_FAIL (msg);
            }
        }

        public void close () {
            device.close ();
        }
    }

    public class DeviceInfo {
        public int card { get; set; }
        public int device { get; set; }
        public string card_name { get; set; }
        public string device_name { get; set; }
        public string get_id () { return "plughw:%d:%d".printf (card, device); }
    }

    /* Adapted from
    * https://raw.githubusercontent.com/robelsharma/IdeaAudio/v1.0/IdeaLib/AudioAlsa.cpp */
    public DeviceInfo[] get_device_infos (PcmStream stream = PcmStream.CAPTURE) {
        CardInfo card_info;
        PcmInfo pcm_info;
        CardInfo.alloc (out card_info);
        PcmInfo.malloc (out pcm_info);
        var infos = new Array<DeviceInfo> ();
        int card_no = -1;
        while (snd_card_next (&card_no) >= 0 && card_no >= 0) {
            debug ("Card: %d", card_no);
            int err = 0;
            Card card;
            if ((err = Card.open (out card, "hw:%d".printf(card_no))) < 0) {
                continue;
            }
            if ((err = card.card_info (card_info)) < 0) {
                continue;
            }
            int dev = -1;
            while (snd_ctl_pcm_next_device(card, &dev) >= 0 && dev >= 0) {
                pcm_info.set_device (dev);
                pcm_info.set_subdevice (0);
                pcm_info.set_stream (stream);
                if ((err = snd_ctl_pcm_info(card, pcm_info)) < 0) {
                    continue;
                }
                var info = new DeviceInfo ();
                info.card = card_no;
                info.device = dev;
                /* HACK: Vala tries to free these strings after use which results in SIGABRT.
                 * Most likely a bug in Alsa vapi as they would probably behave correctly if the
                 * return types were unowned. This workaround makes a copy of those strings without
                 * involving ref counter. */
                char *name = pcm_info.get_name ();
                //  char *device = pcm_info.get_subdevice_name (); // This one as well
                info.card_name = card_info.get_id ();
                info.device_name = strdup ((string) name);
                infos.append_val (info);
            }
        }
        return infos.data;
    }

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_card_next")]
    private extern int snd_card_next (int *rcard);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_next_device")]
    private extern int snd_ctl_pcm_next_device (Card card, int *device);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_info")]
    private extern int snd_ctl_pcm_info (Card card, PcmInfo info);
}
