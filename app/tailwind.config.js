module.exports = {
  mode: 'jit',
  purge: ['./src/**/*.bs.js'],
  darkMode: 'media',
  theme: {
    extend: {
      width: {
        'frame': '600px',
      },
      height: {
        'content': 'calc(100% - 56px)'
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
