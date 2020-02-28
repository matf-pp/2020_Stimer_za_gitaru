namespace Strings {
    public struct Complex {
        double real;
        double im;

        public Complex (double real = 0.0, double im = 0.0) {
            this.real = real;
            this.im = im;
        }

        public string to_string () {
            return "(%lf, %lf)".printf (real, im);
        }

        public Complex multiply (Complex b) {
            return Complex (
                real * b.real - im * b.im,
                real * b.im + im * b.real
            );
        }

        public Complex add (Complex b) {
            return Complex (real + b.real, im + b.im);
        }

        public Complex subtract (Complex b) {
            return Complex (real - b.real, im - b.im);
        }

        public static void swap (ref Complex a, ref Complex b) {
            Complex tmp = a;
            a = b;
            b = tmp;
        }
    }
}