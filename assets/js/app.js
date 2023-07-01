// Tell esbuild to output our css bundler
import "../css/app.css"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {};

Hooks.Tooltip = {
  mounted() {
    let text = (this.el.getAttribute('alt') || this.el.getAttribute('phx-tooltip')).trim();

    let tooltip = document.createElement("div");
    tooltip.setAttribute("class", "tooltip");
    tooltip.appendChild(document.createTextNode(text));

    this.el.addEventListener("mousemove", (event) => {
      let scrollY = window.scrollY || window.pageYOffset;
      let scrollX = window.scrollX || window.pageXOffset;
      let tooltipTop = (event.pageY - scrollY + tooltip.offsetHeight + 20 >= window.innerHeight ? (event.pageY - tooltip.offsetHeight - 20) : event.pageY);
      let tooltipLeft = (event.pageX - scrollX + tooltip.offsetWidth + 20 >= window.innerWidth ? (event.pageX - tooltip.offsetWidth - 20) : event.pageX);

      tooltip.style.top = tooltipTop + "px";
      tooltip.style.left = tooltipLeft + "px";
    });

    this.el.addEventListener("mouseover", () => { document.querySelector("body").appendChild(tooltip); });
    this.el.addEventListener("mouseout", () => {	document.querySelector("body").removeChild(tooltip); });
  }
}

Hooks.Flash = {
  mounted(){
    let hide = () => liveSocket.execJS(this.el, this.el.getAttribute("phx-click"))
    this.timer = setTimeout(() => hide(), 4000)
    this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer))
    this.el.addEventListener("mouseover", () => {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => hide(), 4000)
    })
  },
  destroyed(){ clearTimeout(this.timer) }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
