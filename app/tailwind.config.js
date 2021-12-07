module.exports = {
  mode: 'jit',
  purge: ['./src/**/*.bs.js'],
  darkMode: 'media',
  theme: {
    extend: {
      width: {
        'frame': '600px',
        'currency_box_w': '200px',
      },
      height: {
        'content': 'calc(100% - 56px)',
        'currency_box_h': '200px',
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
