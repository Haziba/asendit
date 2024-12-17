import { Controller } from "@hotwired/stimulus"
import { useDebounce } from 'stimulus-use'

// Connects to data-controller="map"
export default class extends Controller {
  static targets = ["map", "routeSets", "done", "lock", "nextButton", "prevButton", "floorplanName", "floorplan", "route", "routeSetButton"];
  static debounces = ['updateServer']
  static values = { currentFloorplanIndex: Number }

  connect() {
    this.climbPath = this.data.get("climbPath");
    this.routeSets = JSON.parse(this.data.get("routes"));
    this.defaultMapTint = this.data.get("defaultMapTint");
    this.routeSetLibrary = JSON.parse(this.data.get("routeSets"));
    this.previousStates = JSON.parse(this.data.get("previousStates"));
    this.newWins = JSON.parse(this.data.get("newWins"));
    this.floorplanData = JSON.parse(this.data.get("floorplanData"));
    this.initialRouteStates = JSON.parse(this.data.get("initialRouteStates"));
    this.editable = this.data.get("editable") === "true";
    this.showNewWinStar = this.data.get("showNewWinStar") === "true";
    this.currentRouteSetBtn = null;
    this.routes = [];
    this.nonDeletedFloorplans = this.floorplanData.filter(item => !item.deleted);

    let imagesLoaded = 0;
    const totalImages = this.floorplanTargets.length;

    this.initFloorplan();
    this.floorplanImages.forEach(floorplan => {
      floorplan.onload = () => {
        imagesLoaded++;
        if (imagesLoaded === totalImages) {
          this.initRouteStates();
          this.changeRoute();
          this.loaded = true;

          if('wakeLock' in navigator) {
            this.lockTarget.classList.remove('visually-hidden')
            this.lockTarget.click(this.toggleLock)
          }
        }
      }
      if (floorplan.complete) floorplan.onload();
    })
  };

  initFloorplan() {
    this.floorplanImages = this.floorplanData.map(floorplan => {
      const img = new Image();
      img.src = this.floorplanTargets.find(fp => fp.dataset.floorplanId == floorplan.id).src;
      return img;
    })
  }

  initRouteStates() {
    Object.keys(this.routeSets).forEach(routeSetKey => {
      this.routeSets[routeSetKey].forEach(route => {
        const routeState = this.initialRouteStates.filter(initialRouteState => initialRouteState.route_id == route.id)[0]

        if(!routeState)
          return
        route.status = routeState.status
      })
    })
  }

  next() {
    this.currentFloorplanIndexValue++;
  }

  prev() {
    this.currentFloorplanIndexValue--;
  }

  currentFloorplanIndexValueChanged() {
    if(this.loaded)
      this.switchFloorplan(this.currentFloorplan());
  }

  switchFloorplan(floorplan) {
    this.floorplanNameTarget.innerHTML = floorplan.name;
    this.floorplanTargets.forEach(fp => fp.hidden = true);
    this.floorplanTargets.filter(fp => fp.dataset.floorplanId == floorplan.id)[0].hidden = false;
    this.routeTargets.forEach(route => route.hidden = true);
    this.routeTargets.filter(route => route.dataset.floor == floorplan.id).forEach(route => route.hidden = false);
    this.currentFloorplanIndexValue = this.nonDeletedFloorplans.indexOf(floorplan);
  }

  changeRoute(e) {
    if(this.isLocked())
      return

    this.routeTargets.forEach(route => {
      route.remove()
    })

    if(this.currentRouteSetBtn) {
      this.currentRouteSetBtn.removeClass('current')
      this.currentRouteSetBtn.removeAttr('disabled')
    }

    if(this.routeSets.length > 1) {
      this.currentRouteSetBtn = e ? e.currentTarget : this.routeSetButtonTargets[0]
      const routeSetId = $currentRouteSetBtn.data('routeSetId')

      const newRoutes = this.routeSets[routeSetId]
      newRoutes.forEach(route => this.addRoute(route))

      $map.css('background-color', this.currentRouteSetBtn.data('tint-colour'))
      this.currentRouteSetBtn.addClass('current')
      this.currentRouteSetBtn.attr('disabled', true)
    } else {
      this.routeSets[Object.keys(this.routeSets)[0]].forEach(route => this.addRoute(route))

      this.mapTarget.style['background-color'] = this.defaultMapTint;
    }

    this.switchFloorplan(this.currentFloorplan())
  }

  addRoute(route) {
    const $route = document.createElement("div");
    $route.className = "route";
    $route.dataset.routeId = route.id;
    $route.style.left = `${(route.pos_x / this.floorplanImages[route.floor].naturalWidth) * 100}%`;
    $route.style.top = `${(route.pos_y / this.floorplanImages[route.floor].naturalHeight) * 100}%`;
    $route.dataset.floor = route.floor;
    if (this.editable) {
      $route.setAttribute("data-action", "click->map#clickRoute");
    }

    $route.innerHTML = this.icon(route);

    route.$elem = $route
    this.mapTarget.appendChild($route)
    this.routeTargets.push($route)
  }

  icon(route) {
    let icon = ''

    if(this.showNewWinStar) {
      const newWin = this.newWins.filter(newWin => newWin.route_id == route.id)[0]

      if(newWin)
        icon = '⭐'
    }

    switch(route.status) {
      case 'flashed':
        return `${icon}⚡`
      case 'sent':
        return `${icon}✔`
      case 'failed':
        return '❌'
    }

    switch(this.previousStates[route.id]) {
      case 'sent':
        return '🟢'
      case 'failed':
        return '🟡'
      default:
        return '🔴'
    }
  }

  clickRoute(e) {
    if(this.isLocked())
        return

    const route = Object.values(this.routeSets).flat().find(r => r.id == e.currentTarget.dataset.routeId)

    const statusOrder = ['failed', 'sent', 'flashed']
    const nextStatusIndex = statusOrder.indexOf(route.status) + 1
    route.status = statusOrder[nextStatusIndex]

    route.$elem.innerHTML = this.icon(route)

    this.updateServer()
  }

  updateServer() {
    useDebounce(this, { wait: 1000 })

    const routeStates = Object.keys(this.routeSets).map(routeSetId => 
      this.routeSets[routeSetId].map(route => ({
        routeId: route.id,
        status: route.status || 'not_attempted'
      }))
    ).flat()

    fetch(this.climbPath,
      {
        method: 'PATCH',
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          route_states: routeStates
        })
      })
  }

  currentFloorplan() {
    let index = this.currentFloorplanIndexValue;
    if (index < 0) {
      index = this.nonDeletedFloorplans.length - 1;
    }
    return this.nonDeletedFloorplans[index % this.nonDeletedFloorplans.length];
  }

  isLocked() {
    return !!this.lockTarget.wakeLock
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
}
