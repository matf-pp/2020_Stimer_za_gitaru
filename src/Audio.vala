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

namespace Strings.Audio {

    public struct Sample : int16 { }

    public errordomain DeviceError {
        INIT_FAIL,
        RECORD_FAIL
    }

    public interface Device : Object {
        public abstract int frame_size { get; set; }
        public abstract int sample_rate { get; set; }
        public abstract int channels { get; set; }

        public abstract void init () throws DeviceError;
        public abstract void play (Sample[] buffer) throws DeviceError;
        public abstract void record (Sample[] buffer) throws DeviceError;
        public abstract void close ();
    }

    public void fft (Complex[] buff) {
        var length = buff.length;
        assert (length != 0 && (length & (length - 1)) == 0);

        for (var i = 1, j = 0; i < length; i++) {
            var bit = length >> 1;
            for (; j >= bit; bit >>= 1) { j -= bit; }
            j += bit;
            if (i < j) {
                Complex.swap (ref buff[i], ref buff[j]);
            }
        }

        for (var k = 2; k <= length; k <<= 1) {
            double angle = 2.0 * Math.PI / -k;
            Complex w_n = { Math.cos (angle), Math.sin (angle) };
            for (var i = 0; i < length; i += k) {
                Complex w = { 1.0, 0.0 };
                for (var j = 0; j < k / 2; j++) {
                    Complex t = buff[i + j + k / 2].multiply (w);
                    buff[i + j + k / 2] = buff[i + j].subtract (t);
                    buff[i + j] = buff[i + j].add (t);
                    w = w.multiply (w_n);
                }
            }
        }
    }
}