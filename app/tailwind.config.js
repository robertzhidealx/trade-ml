module.exports = {
  content: ['./src/**/*.bs.js'],
  theme: {
    backgroundColor: theme => ({
      ...theme('colors'),
      'frame': '#f0f2f5',
    }),
    extend: {
      width: {
        'frame': '600px',
      },
      height: {
        'content': 'calc(100% - 56px)',
      },
      margin: {
        'less_scrollbar': '39px'
      }
    },
  },
  plugins: [],
}
