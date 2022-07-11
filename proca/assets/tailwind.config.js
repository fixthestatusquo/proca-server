module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*eex'
  ],
  theme: {
    fontFamily: {
      sans: ['Titillium Web', 'sans-serif'],
    },
    extend: {
      colors: {
        primary: {
          DEFAULT: 'rgb(255, 92, 57)',
          light: '#FF5D32',
        },
        secondary: {
          DEFAULT: 'rgb(72, 92, 199)',
          light: '#5375E6',
        },
        'logo-gray': {
          DEFAULT: 'rgb(84, 88, 90)'
        },
      }
    }
  },
  plugins: [
  ],
}
