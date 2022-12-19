import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const form = event.target.closest('form')

    if (this.isSelectAndSearch(event.target)) {
      if (event.target.nextElementSibling.value != '') {
        // Let the select_and_search active admin JS do its job first
        setTimeout(() => { form.requestSubmit() }, 50)
      }
    } else {
      form.requestSubmit()
    }
  }

  isSelectAndSearch(el) {
    return (el.tagName == 'SELECT' &&
      el.closest('div').classList.contains('select_and_search'))
  }
}
