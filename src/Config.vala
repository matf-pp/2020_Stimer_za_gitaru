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

using Strings.Audio;

namespace Strings {
    public class Config {
        [CCode (cname="GETTEXT_PACKAGE", cprefix = "", cheader_filename = "config.h")]
        public extern const string GETTEXT_PACKAGE;

        [CCode (cname="APPLICATION_ID", cprefix = "", cheader_filename = "config.h")]
        public extern const string APPLICATION_ID;

        protected static Config _instance;

        public static Config instance {
            get {
                if (_instance == null) { _instance = new Config (); }
                return _instance;
            }
        }

        protected Config () {
            scale = new Tuning.StandardConcertScale ();
            automatic_tuning = true;
        }

        public Tuning.Scale scale { get; set; }

        public bool automatic_tuning { get; set; }
    }
}