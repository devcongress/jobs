const { execSync } = require('child_process');
const plutoniumGemPath = execSync("bundle show plutonium").toString().trim();
const plutoniumTailwindConfig = require(`${plutoniumGemPath}/tailwind.options.js`)
const tailwindPlugin = require('tailwindcss/plugin')

module.exports = {
  darkMode: plutoniumTailwindConfig.darkMode,
  plugins: [
    // add plugins here
  ].concat(plutoniumTailwindConfig.plugins.map(function (plugin) {
    switch (typeof plugin) {
      case "function":
        return tailwindPlugin(plugin)
      case "string":
        return require(plugin)
      default:
        throw Error(`unsupported plugin: ${plugin}: ${(typeof plugin)}`)
    }
  })),
  theme: plutoniumTailwindConfig.merge(
    plutoniumTailwindConfig.theme,
    {
      // DevCongress brand (devcongress.org): hot pink on cream, yellow
      // highlights, ink-black borders. 500 is the brand pink; 600 is a touch
      // deeper so white button text and links pass WCAG AA.
      extend: {
        colors: {
          primary: {
            50: '#FDF2F8',
            100: '#FCE7F3',
            200: '#FBCFE8',
            300: '#F9A8D4',
            400: '#F45AA6',
            500: '#E8117F',
            600: '#D10F72',
            700: '#B00C60',
            800: '#8F0D4F',
            900: '#760F44',
            950: '#4A0326',
          },
          brand: {
            pink: '#E8117F',
            yellow: '#F5E642',
            ink: '#111111',
            cream: '#F5F2E8',
          },
        },
        fontFamily: {
          body: ['"Inter Variable"', 'Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
          sans: ['"Inter Variable"', 'Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
          display: ['"DM Serif Display"', 'Georgia', 'serif'],
        },
      },
    },
  ),
  content: [
    `${__dirname}/app/**/*.{erb,haml,html,slim,rb}`,
    `${__dirname}/app/javascript/**/*.js`,
    `${__dirname}/packages/**/app/**/*.{erb,haml,html,slim,rb}`,
  ].concat(plutoniumTailwindConfig.content),
}
