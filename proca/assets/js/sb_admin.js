import bootstrap from "bootstrap.native/dist/bootstrap-native-v4"


function collapseSidebar() {
  document.querySelectorAll(".sidebar .collapse").forEach((c) => {
    c.Collapse.hide()
    // bootstrap.Collapse(c).hide()
  })
}

document.addEventListener('DOMContentLoaded', () => {

  // Toggle the side navigation
  let st = document.querySelectorAll("#sidebarToggle, #sidebarToggleTop")
  st.forEach((x) => {
    x.addEventListener("click", (ev) => {
      document.querySelector("body").classList.toggle("sidebar-toggled")

      document.querySelector(".sidebar").classList.toggle("toggled")

      if (sb.classList.contains("toggled")) {
        collapseSidebar()
      }
    })
  })


  // Close any open menu accordions when window is resized below 768px
  window.addEventListener("resize", (ev) => {
    if (window.innerWidth < 768)  {
      collapseSidebar()
    }
  })


  window.addEventListener("scroll", (ev) => {
    let scrollDistance = window.pageYOffset
    if (scrollDistance > 100) {
      document.querySelector(".scroll-to-top").classList.remove("hidden")
    } else {
      document.querySelector(".scroll-to-top").classList.add("hidden")
    }
  })

});
