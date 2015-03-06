`import DS from 'ember-data'`
`import InvoiceBase from 'vosae/models/invoice-base'`
`import vosaeSettings from 'vosae/conf/settings'`

###
 * A data model that represents an invoice.
 * @class Invoice
 * @extends InvoiceBase
###

Invoice = InvoiceBase.extend
  state: DS.attr('string')
  paid: DS.attr('number')
  balance: DS.attr('number')
  hasTemporaryReference: DS.attr('boolean', defaultValue: true)
  currentRevision: DS.belongsTo('invoiceRevision')
  # revisions: DS.hasMany('invoiceRevision')
  payments: DS.hasMany('payment', async: true)

  isInvoice: true

  displayState: (->
    # Returns the current state readable and translated.
    vosaeSettings.invoiceStatesChoices.findProperty('value', @get('state')).get('label')
  ).property('state')

  canAddPayment: (->
    # Determine if a `Payment` can be added to the `Invoice`.
    if @get('isSaving') or not @get('isPayable')
      return false
    if @get('balance') > 0
      uncommitedPayments = @get('payments').filterProperty('id', null)
      return true if uncommitedPayments.length is 0
    return false
  ).property('balance', 'payments.@each.id', 'isSaving')

  availableStates: (->
    # List the available states for the `Invoice`, depending of its current state.
    if @get('state') is "DRAFT"
      vosaeSettings.invoiceStatesChoices.filter (state) ->
        if ["REGISTERED"].contains state.get('value')
          state
    else if @get('state') is "REGISTERED"
      vosaeSettings.invoiceStatesChoices.filter (state) ->
        if ["CANCELLED"].contains state.get('value')
          state
    else if @get('state') is "OVERDUE"
      vosaeSettings.invoiceStatesChoices.filter (state) ->
        if ["CANCELLED"].contains state.get('value')
          state
    else if @get('state') is "PART_PAID"
      vosaeSettings.invoiceStatesChoices.filter (state) ->
        if ["CANCELLED"].contains state.get('value')
          state
    else if @get('state') is "PAID"
      vosaeSettings.invoiceStatesChoices.filter (state) ->
        if ["CANCELLED"].contains state.get('value')
          state
    else
      return []
  ).property('state')

  isModifiable: (->
    # True if the `Invoice` is still in a modifiable state.
    if ["DRAFT"].contains @get('state')
      return true
    return false
  ).property('state')

  isDeletable: (->
    # Determine if the `Invoice` could be deleted.
    if @get 'isModifiable'
      return true
    return false
  ).property('state')

  isCancelable: (->
    # True if the `Invoice` is in a cancelable state.
    # When cancelable, a credit note could be created.
    if ["REGISTERED", "OVERDUE", "PART_PAID", "PAID"].contains @get('state')
      return true
    return false
  ).property('state')

  isPayable: (->
    # True if the `Invoice` is in a payable state.
    if ["REGISTERED", "OVERDUE", "PART_PAID"].contains @get('state')
      return true
    return false
  ).property('state')

  isIssuable: (->
    # Determine if the `Quotation` could be sent.
    if ["DRAFT", "CANCELLED"].contains @get('state')
      return true
    return false
  ).property('state')

  isPayableOrPaid: (->
    # True if invoice is Payable or Paid
    if @get('isPayable') or @get('isPaid')
      return true
    return false
  ).property('isPayable', 'isPaid')

  isPaid: (->
    # True if the `Invoice` is paid.
    if @get('state') is "PAID"
      return true
    return false
  ).property('state')

  isDraft: (->
    # True if the `Invoice` is draft.
    if @get('state') is "DRAFT"
      return true
    return false
  ).property('state')

  isCancelled: (->
    # True if the `Invoice` is cancelled.
    if @get('state') is "CANCELLED"
      return true
    return false
  ).property('state')

  isInvoicable: (->
    # True if the `Invoice` is invoicable.
    unless @get('state')
      return false
    unless @get('state') is "DRAFT"
      return false
    if not @get('contact') and not @get('organization')
      return false
    if not @get('currentRevision.invoicingDate') or (not @get('currentRevision.dueDate') and not @get('currentRevision.customPaymentConditions'))
      return false
    if @get('currentRevision.lineItems.length') < 1
      return false
    return true
  ).property(
    'state',
    'contact',
    'organization',
    'currentRevision.invoicingDate',
    'currentRevision.dueDate',
    'currentRevision.customPaymentConditions',
    'currentRevision.lineItems',
    'currentRevision.lineItems.length'
  )

  getErrors: ->
    # Return an array of string that contains form validation errors
    errors = []
    errors = errors.concat @get("currentRevision").getErrors("Invoice")
    return errors

`export default Invoice`
