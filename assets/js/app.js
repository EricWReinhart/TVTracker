// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Chart from "chart.js/auto"
import DragHook from "./drag_hook";
import "flowbite";

// // adds or removes the 'dark' class from <html> based on the `theme` in localStorage,
// // if given, or default preference otherwise.
// function set_theme() {
//   if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
//     document.documentElement.classList.add('dark')
//   } else {
//     document.documentElement.classList.remove('dark')
//   }
// }

// // Exposes function to toggle dark mode on and off.
// window.toggleDarkMode = () => {
//   if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
//     localStorage.theme = 'light'
//   } else {
//     localStorage.theme = 'dark'
//   }
//   set_theme()
// }

// // set theme on page load
// set_theme()

// Function to toggle dark mode
window.toggleDarkMode = () => {
  let currentTheme = localStorage.getItem("theme");

  // Determine new theme
  let newTheme = currentTheme === "dark" ? "light" : "dark";
  localStorage.setItem("theme", newTheme);

  // Apply the theme immediately
  document.documentElement.classList.toggle("dark", newTheme === "dark");

  // Dispatch event to update the chart theme
  const event = new Event('classChange');
  document.documentElement.dispatchEvent(event);
};


// Ensure the correct theme is applied on page load
document.addEventListener("DOMContentLoaded", () => {
  let savedTheme = localStorage.getItem("theme") || "light";
  document.documentElement.classList.toggle("dark", savedTheme === "dark");
});

// let liveSocketPath = process.env.NODE_ENV === "production" ? "/csci379-25s-h/live" : "/live";
let liveSocket = new LiveSocket(liveSocketPath, Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// create hooks for logout
let Hooks = {}; // this may already be here

Hooks.LogoutButton = {
  mounted() {
    this.handleEvent("logout", () => {
      let btn = document.getElementById("logout-button");
      if (btn) btn.click();
    });
  }
};

Hooks.AutoScroll = {
  updated() {
    window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });
  }
};

// Hooks.Chart = {
//   mounted() {
//     this.el._chart = new Chart(this.el, JSON.parse(this.el.dataset.config));
//     // call update them method
//   },

//   // update theme method if dark mode

//   updated() {
//     // .destroy first chart
//     const new_config = JSON.parse(this.el.dataset.config)
//     this.el._chart.data = new_config.data
//     this.el._chart.update()
//   }
// }

Hooks.Chart = {
  mounted() {
    // Initialize chart
    this.el._chart = new Chart(this.el, JSON.parse(this.el.dataset.config));
    this.updateTheme();

    // Listen for theme changes based on the class "dark" in <html>
    this.themeListener = () => {
      this.updateTheme();
    };
    document.documentElement.addEventListener('classChange', this.themeListener);
  },

  updated() {
    // Debugging logs to track if updated is being triggered
    console.log('Chart updated - checking dataset.config:', this.el.dataset.config);

    const newConfig = JSON.parse(this.el.dataset.config);

    // Debugging logs to ensure newConfig is correct
    console.log('New chart configuration:', newConfig);

    // Check if the chart already exists
    if (this.el._chart) {
      // Log that we're destroying the old chart
      console.log('Destroying old chart...');
      this.el._chart.destroy(); // Destroy old chart instance
    }

    // Reinitialize the chart with the new config
    console.log('Creating new chart...');
    this.el._chart = new Chart(this.el, newConfig);

    // Update the theme for the new chart
    this.updateTheme();
  },

  updateTheme() {
    // Check for dark mode
    const isDarkMode = document.documentElement.classList.contains("dark");
    const color = isDarkMode ? "#fff" : "#000";
    const gridColor = isDarkMode ? "#444" : "#ccc";

    // Update chart text colors based on theme
    this.el._chart.options.plugins.legend.labels.color = color;
    this.el._chart.options.plugins.title.color = color;
    this.el._chart.options.scales.x.title.color = color;
    this.el._chart.options.scales.x.ticks.color = color;
    this.el._chart.options.scales.x.grid.color = gridColor;
    this.el._chart.options.scales.y.title.color = color;
    this.el._chart.options.scales.y.ticks.color = color;
    this.el._chart.options.scales.y.grid.color = gridColor;

    // Apply the changes to the chart
    this.el._chart.update();
  },

  destroyed() {
    // Clean up the event listener when the component is destroyed
    document.documentElement.removeEventListener('classChange', this.themeListener);
  }
};

// CheapShark chart hook (for the line chart showing game prices)
Hooks.ChartDeals = {
  mounted() {
    this.el._chart = new Chart(this.el, JSON.parse(this.el.dataset.config));
    this.updateTheme();

    // Listen for theme changes based on the class "dark" in <html>
    this.themeListener = () => {
      this.updateTheme();
    };
    document.documentElement.addEventListener('classChange', this.themeListener);
  },

  updated() {
    const newConfig = JSON.parse(this.el.dataset.config);
    if (this.el._chart) {
      this.el._chart.destroy(); // Destroy old chart instance
    }

    this.el._chart = new Chart(this.el, newConfig);
    this.updateTheme();
  },

  updateTheme() {
    const isDarkMode = document.documentElement.classList.contains("dark");
    const color = isDarkMode ? "#fff" : "#000";
    const gridColor = isDarkMode ? "#444" : "#ccc";

    // Update chart text colors based on theme
    this.el._chart.options.plugins.legend.labels.color = color;
    this.el._chart.options.plugins.title.color = color;
    this.el._chart.options.scales.x.title.color = color;
    this.el._chart.options.scales.x.ticks.color = color;
    this.el._chart.options.scales.x.grid.color = gridColor;
    this.el._chart.options.scales.y.title.color = color;
    this.el._chart.options.scales.y.ticks.color = color;
    this.el._chart.options.scales.y.grid.color = gridColor;

    this.el._chart.update();
  },

  destroyed() {
    // Clean up the event listener when the component is destroyed
    document.documentElement.removeEventListener('classChange', this.themeListener);
  }
}



// final project: tv / movie rater
Hooks.RatingValidator = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      let value = e.target.value;

      // Match a number with 1 decimal point or an integer (e.g., 2.5, 2)
      let regex = /^(?:[0-9]|10)(?:\.\d{0,1})?$/;

      // Ensure the value is within the range of 0 to 10, including decimals
      if (!regex.test(value) || parseFloat(value) > 10 || parseFloat(value) < 0) {
        e.target.value = value.slice(0, -1); // Remove last character
      }
    });
  }
};

Hooks.Rating = {
  mounted() {
    this.el.addEventListener("rating-changed", e => {
      let newRating = e.detail.rating;
      this.pushEvent("rating_updated", { rating: newRating });
    });
  }
}


Hooks.DragHook = DragHook




Hooks.Downloader = {
  mounted() {
    this.handleEvent("download_media_backup", ({ filename, content }) => {
      // create a blob, trigger a download
      const blob = new Blob([content], { type: "application/json" })
      const url  = URL.createObjectURL(blob)
      const a    = document.createElement("a")
      a.href     = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    })
  }
}



// add hook to your LiveView connect (this may already be here):
let liveSocket = new LiveSocket(liveSocketPath, Socket, {
  // longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})


// allow modals to be opened from server
window.addEventListener("phx:open-modal", e => {
  el = document.getElementById(e.detail.id)
  liveSocket.execJS(el, el.getAttribute("data-open"))
})

// allow modals to be closed from server
window.addEventListener("phx:close-modal", e => {
  el = document.getElementById(e.detail.id)
  liveSocket.execJS(el, el.getAttribute("data-close"))
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

