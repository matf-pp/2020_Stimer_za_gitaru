namespace Strings {
    public struct Complex {
        double real;
        double im;

        public string to_string () {
            return "(%lf, %lf)".printf (real, im);
        }

        public Complex multiply (Complex b) {
            return {
                real * b.real - im * b.im,
                real * b.im + im * b.real
            };
        }

        public Complex add (Complex b) {
            return { real + b.real, im + b.im };
        }

        public Complex subtract (Complex b) {
            return { real - b.real, im - b.im };
        }

        public double arg () {
            return Math.tan (im / real);
        }

        public double magn_squared () {
            return real * real + im * im;
        }

        public double magnitude () {
            return Math.sqrt (magn_squared ());
        }

        public static void swap (ref Complex a, ref Complex b) {
            Complex tmp = a;
            a = b;
            b = tmp;
        }

        public static size_t argmax (Complex[] array) {
            assert (array.length > 0);
            var max_i = 0;
            var max_mgn = array[0].magn_squared ();
            for (var i = 1; i < array.length; i++) {
                var i_mgn = array[i].magn_squared ();
                if (i_mgn > max_mgn) {
                    max_i = i;
                    max_mgn = i_mgn;
                }
            }
            return max_i;
        }
    }
}