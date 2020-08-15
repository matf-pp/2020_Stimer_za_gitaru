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

namespace Strings.Audio.Tuning {

    public struct Instrument {
        string name;
        double[] tones;
    }

    public struct ToneInfo {
        double frequency;
        ushort octave;
        string name;
        bool sharp;

        public string to_string () {
            return string.join(sharp ? "#" : "", name, octave.to_string ());
        }

        public string to_pango_markup () {
            return string.join (sharp ? "<sup>#</sup>" : "", name, "<sub>%d</sub>".printf(octave));
        }
    }


    /** NOTE: Still not accurately named but not sure how a set of tones
     * according to which instrument is tuned is called. (e.g. a set of tones
     * generated from standard concert pitch (A = 440.00Hz)) */
    public interface TuningStandard : Object {

        public abstract uint length { get; }

        public abstract uint closest_tone_index (double frequency);

        public abstract uint next_tone_index (uint index);

        public abstract uint previous_tone_index (uint index);

        public abstract void tone_info (uint index, ref ToneInfo info);
    }

    // Reference: https://en.wikipedia.org/wiki/Concert_pitch
    public class StandardConcertTuning : TuningStandard, Object {

        /* Tones from C0 to B8 */
        public const double[] TONES = {
            //C       C#      D       D#      E       F       F#      G       G#      A       A#      B
            16.352, 17.324,	18.354,	19.445,	20.602,	21.827,	23.125,	24.500,	25.957,	27.500,	29.135,	30.868,
            32.703, 34.648,	36.708,	38.891,	41.203,	43.654,	46.249,	48.999,	51.913,	55.000,	58.270,	61.735,
            65.406, 69.296,	73.416,	77.782,	82.407,	87.307,	92.499,	97.999,	103.83,	110.00,	116.54,	123.47,
            130.81, 138.59,	146.83,	155.56,	164.81,	174.61,	185.00,	196.00,	207.65,	220.00,	233.08,	246.94,
            261.63, 277.18,	293.66,	311.13,	329.63,	349.23,	369.99,	392.00,	415.30,	440.00,	466.16,	493.88,
            523.25, 554.37,	587.33,	622.25,	659.26,	698.46,	739.99,	783.99,	830.61,	880.00,	932.33,	987.77,
            1046.5, 1108.7,	1174.7,	1244.5,	1318.5,	1396.9,	1480.0,	1568.0,	1661.2,	1760.0,	1864.7,	1975.5,
            2093.0, 2217.5,	2349.3,	2489.0,	2637.0, 2793.8, 2960.0, 3136.0, 3322.4, 3520.0, 3729.3, 3951.1,
            4186.0, 4434.9, 4698.6, 4978.0, 5274.0, 5587.7, 5919.9, 6271.9, 6644.9, 7040.0, 7458.6, 7902.1
        };

        public uint length { get { return TONES.length; } }

        public uint closest_tone_index (double frequency) {
            var lo = 0;
            var hi = TONES.length - 1; var pos = 0;
            if (frequency <= TONES[lo]) {
                pos = lo;
            } else if (frequency >= TONES[hi]) {
                pos = hi;
            } else {
                while (lo <= hi) {
                    pos = lo + (hi - lo) / 2;
                    if (TONES[pos] == frequency) { break; }
                    if (TONES[pos] < frequency) {
                        lo = pos + 1;
                    } else {
                        hi = pos - 1;
                    }
                }
            }
            return pos;
        }

        public uint next_tone_index (uint index) {
            return index < TONES.length - 1 ? index + 1 : index;
        }

        public uint previous_tone_index (uint index) {
            return index > 0 ? index - 1 : 0;
        }

        public void tone_info (uint index, ref ToneInfo info) {
            assert (index >= 0 && index < TONES.length);
            info.frequency = TONES[index];
            info.octave = (uint8) (index / 12);
            var oct_pos = index % 12;
            info.sharp = (oct_pos < 4 && oct_pos % 2 == 1) || (oct_pos > 4 && oct_pos % 2 == 0);
            const string[] names = { "C", "C", "D", "D", "E", "F", "F", "G", "G", "A", "A", "B" };
            info.name = names[oct_pos];
        }
    }
}