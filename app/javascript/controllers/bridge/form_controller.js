import { BridgeComponent, BridgeElement } from "@hotwired/strada"

export default class extends BridgeComponent {
  static component = "form"
  static targets = ["submit"]

  connect() {
    super.connect()
    this.#notifyBridgeOfConnect()
  }

  #notifyBridgeOfConnect() {
    // gather data from the HTML
    const submitButton = new BridgeElement(this.submitTarget)
    const submitTitle = submitButton.title // text you send to the native component

    // send to the native component
    // event that we are going to send, data, callback triggered when native component replies to the event back to web component (click submit on the web form)
    this.send("connect", {submitTitle}, () => {
      this.submitTarget.click()
    })
  }
}
