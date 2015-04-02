`import DS from 'ember-data'`
`import formatMoney from 'accounting/format-money'`
`import {gettext} from 'vosae/utils/i18n'`

###
 * A data model that represents an invoice revision.
 * @class BaseRevision
 * @extends DS.Model
###

BaseRevision = DS.Model.extend
  issueDate: DS.attr('date')  # read-only creation date of the invoice revision
  customPaymentConditions: DS.attr('string')  # payment conditions, can replace due date considered in this case as an estimation
  revision: DS.attr('string')
  state: DS.attr('string')
  sender: DS.attr('string')
  customerReference: DS.attr('string')
  taxesApplication: DS.attr('string')
  lineItems: DS.hasMany('lineItem')
  pdf: DS.belongsTo('localizedFile')
  organization: DS.belongsTo('organization', async: true)
  issuer: DS.belongsTo('user', async: true)
  contact: DS.belongsTo('contact', async: true)
  senderAddress: DS.belongsTo('address')
  billingAddress: DS.belongsTo('address')
  deliveryAddress: DS.belongsTo('address')
  currency: DS.belongsTo('snapshotCurrency')

  billingAddressChanged: (->
    Ember.run.once @, 'updateDeliveryAddress'
  ).observes("billingAddress")

  # As long as delivery address can't be set in forms, we set
  # content from the billing address
  updateDeliveryAddress: ->
    @get("deliveryAddress").dumpDataFrom @get("billingAddress")

  # Returns quotation total
  total: (->
    total = 0
    @get("lineItems").forEach (item) ->
      if not item.get("optional")
        total += item.get("total")
    total
  ).property("lineItems.@each.quantity", "lineItems.@each.unitPrice", "lineItems.@each.optional")

  # Returns quotation total VAT
  totalPlusTax: (->
    total = 0
    @get("lineItems").forEach (item) ->
      if not item.get("optional")
        total += item.get("totalPlusTax")
    total
  ).property("lineItems.@each.quantity", "lineItems.@each.unitPrice", "lineItems.@each.tax", "lineItems.@each.optional")

  # Returns the total formated with accounting
  displayTotal: (->
    formatMoney @get('total')
  ).property("total")

  # Returns the total formated with accounting
  displayTotalPlusTax: (->
    formatMoney @get('totalPlusTax')
  ).property("totalPlusTax")

  # Returns an array with each tax amount
  taxes: (->
    groupedTaxes = []
    @get("lineItems").forEach (lineItem) ->
      if not lineItem.get("optional")
        lineItemTax = lineItem.get('VAT')
        if lineItemTax
          if groupedTaxes.length
            addedd = false
            groupedTaxes.forEach (tax) ->
              if lineItemTax.tax.get("id") is tax.tax.get("id")
                tax.total = tax.total + lineItemTax.total
                addedd = true
            groupedTaxes.pushObject lineItemTax unless addedd
          else
            groupedTaxes.pushObject lineItemTax
    groupedTaxes
  ).property("lineItems.@each.quantity", "lineItems.@each.unitPrice", "lineItems.@each.tax", "lineItems.@each.tax.isLoaded", "lineItems.@each.optional")

  # # Convert each line item price with the new currency
  # _convertLineItemsPrice: (currentCurrency, newCurrency) ->
  #   lineItems = @get 'lineItems'
  #   subPromises = []

  #   new Ember.RSVP.Promise (resolve) =>
  #     resolve() if lineItems.get('length') == 0

  #     # Currency has been updated, convert each line items
  #     lineItems.forEach (lineItem, i) =>
  #       subPromises.push new Ember.RSVP.Promise (resolve) =>
  #         @get('store').find("item", lineItem.get('itemId')).then (item) =>
  #           # Item currency and new invoice currency are the same
  #           if item.get('currency.symbol') is newCurrency.get('symbol')

  #             # If user overridden the unit price
  #             if @_userOverrodeUnitPrice lineItem, item, currentCurrency
  #               exchangeRate = newCurrency.exchangeRateFor currentCurrency.get('symbol')
  #               lineItemPrice = lineItem.get 'unitPrice'

  #               # Then we convert the unit price with new currency
  #               lineItem.set 'unitPrice', (lineItemPrice / exchangeRate).round(2)

  #             # User didn't overide unit price, nothing to convert
  #             else
  #               lineItem.set 'unitPrice', item.get 'unitPrice'

  #           # Item currency and new invoice currency are different
  #           else
  #             # If user overridden the unit price
  #             if @_userOverrodeUnitPrice lineItem, item, currentCurrency
  #               exchangeRate = newCurrency.exchangeRateFor currentCurrency.get('symbol')
  #               lineItemPrice = lineItem.get 'unitPrice'

  #               # Then we convert the unit price with new currency
  #               lineItem.set 'unitPrice', (lineItemPrice / exchangeRate).round(2)

  #             # User didn't override unit price, just convert item price
  #             else
  #               exchangeRate = newCurrency.exchangeRateFor item.get('currency.symbol')
  #               lineItem.set 'unitPrice', (item.get('unitPrice') / exchangeRate).round(2)
  #           # Resolve subPromises
  #           resolve()

  #     Promise.all(subPromises).then () =>
  #       @set 'currency.symbol', newCurrency.get('symbol')
  #       @set 'currency.rates.content', []
  #       @set 'currency.rates.content', newCurrency.get('rates').toArray()
  #       # Resolve mainPromise
  #       resolve()

  # Returns true or false if user overridden an item price
  _userOverrodeUnitPrice: (lineItem, item, currentCurrency) ->
    lineItemPrice = lineItem.get 'unitPrice'
    itemPrice = item.get 'unitPrice'
    exchangeRate = currentCurrency.exchangeRateFor item.get('currency.symbol')

    if lineItemPrice isnt (itemPrice / exchangeRate).round(2)
      return true
    false

  # Returns an array of <Item> ids
  _getLineItemsReferences: ->
    ids = []
    @get('lineItems').forEach (lineItem) ->
      id = lineItem.get 'itemId'
      if id and not ids.contains(id)
        ids.addObject id
    ids

  # Update an invoice revision with a new currency
  updateWithCurrency: (newCurrency) ->
    currentCurrency = @get 'currency'

    # We want to be sure that currencies are different
    if currentCurrency.get('symbol') isnt newCurrency.get('symbol')
      ids = @_getLineItemsReferences()

      # Update <Currency>
      if Ember.isEmpty ids
        @set 'currency.symbol', newCurrency.get('symbol')
        @set 'currency.rates.content', []
        @set 'currency.rates.content', newCurrency.get('rates').toArray()

      # Update all <LineItems> and then the <Currency>
      else
        @get('store').find("item", ids).then (items) =>
          @_convertLineItemsPrice(currentCurrency, newCurrency)

  # Return lineItem's index in the hasMany `lineItems`
  getLineItemIndex: (lineItem) ->
    index = @get('lineItems').indexOf lineItem
    if index != -1
      return index
    undefined

  # getErrors: (type) ->
  #   errors = []

  #   # Organization and Contact
  #   if not @get("organization") and not @get("contact")
  #     if type is "Invoice"
  #       errors.addObject gettext("Invoice must be linked to an organization or a contact")
  #     else if type is "Quotation"
  #       errors.addObject gettext("Quotation must be linked to an organization or a contact")

  #   # Sender address
  #   if not @get("senderAddress") or @get("senderAddress") and not @get("senderAddress.streetAddress")
  #     errors.addObject gettext("Field street address of sender address must not be blank")

  #   # Receiver address
  #   if not @get("billingAddress") or @get("billingAddress") and not @get("billingAddress.streetAddress")
  #     errors.addObject gettext("Field street address of receiver address must not be blank")

  #   # Line items
  #   if @get("lineItems.length") > 0
  #     @get('lineItems').forEach (item) ->
  #       unless item.recordIsEmpty()
  #         unless item.get("reference")
  #           errors.addObject gettext("Items reference must not be blank")
  #         unless item.get("description")
  #           errors.addObject gettext("Items description must not be blank")

  #   # Currency
  #   unless @get("currency")
  #     if type is "Invoice"
  #       errors.addObject gettext("Invoice must have a currency")
  #     else if type is "Quotation"
  #       errors.addObject gettext("Quotation must have a currency")

  #   return errors

`export default BaseRevision`
