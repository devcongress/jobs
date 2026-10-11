// Plutonium's form widgets expect these libraries as browser globals. Plutonium
// loads them from a CDN by default; we bundle them instead so a self-hosted
// deploy has no runtime dependency on jsdelivr (see SelfHostedAssets).
import EasyMDE from "easymde"
import SlimSelect from "slim-select"
import flatpickr from "flatpickr"
import intlTelInput from "intl-tel-input/intlTelInputWithUtils"

window.EasyMDE = EasyMDE
window.SlimSelect = SlimSelect
window.flatpickr = flatpickr
window.intlTelInput = intlTelInput
