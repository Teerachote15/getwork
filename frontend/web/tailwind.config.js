/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "../mobile/assets/**/*.{png,jpg,jpeg,svg,gif}",
    "../mobile/lib/page/**/*.dart",
    "../mobile/widgets/**/*.dart",
    "../mobile/lib/main.dart"
  ],
  theme: {
    extend: {
      colors: {
        primary: "#3A5A99",
        secondary: "#7B668C",
        accent: "#22577A",
      },
    },
  },
  plugins: [],
};
