`import DS from 'ember-data'`
`import formatNumber from 'accounting/format-number'`
`import vosaeSettings from 'vosae/conf/settings'`
`import {pgettext} from 'vosae/utils/i18n'`

###
 * A data model that represents a payment.
 * @class Payment
 * @extends DS.Model
###

Payment = DS.Model.extend
  issuer: DS.belongsTo('user')
  issuedAt: DS.attr('date')
  amount: DS.attr('number')
  currency: DS.belongsTo('currency')
  type: DS.attr('string')
  date: DS.attr('date')
  note: DS.attr('string')
  relatedTo: DS.belongsTo('invoice')

  displayDate: (->
    # Return the date formated
    if @get("date")?
      return moment(@get("date")).format "LL"
    return pgettext("date", "undefined")
  ).property("date")

  displayAmount: (->
    # Display amount formating
    if @get("amount")
      return formatNumber(@get("amount"), precision: 2)
    return ''
  ).property("amount")

  displayType: (->
    # Display the payment type
    if @get("type")
      return vosaeSettings.paymentTypes.findProperty('value', @get('type')).get('label')
    return pgettext("payment type", "undefined")
  ).property("type")

  displayNote: (->
    # Return the note or -
    if @get("note")
      return @get("note")
    return "-"
  ).property("note")

  amountMax: (->
    # Return the amount maximum converted with current currency.
    paymentCur = @get('currency')
    invoiceCur = @get('relatedTo.currentRevision.currency')
    amountMax = invoiceCur.toCurrency paymentCur.get('symbol'), @get('relatedTo.balance')
    return amountMax.round(2)
  ).property("relatedTo.balance", "relatedTo.currentRevision.currency.symbol", "currency.symbol")

  updateWithCurrency: (currencyTo) ->
    # Convert amount if `Payment.currency` is
    # different than `Invoice.currentRevision.currency`
    paymentCurrency = @get('currency')
    invoiceCurrency = @get('relatedTo.currentRevision.currency')

    unless currencyTo.get('symbol') is paymentCurrency.get('symbol')
      amount = invoiceCurrency.fromCurrency paymentCurrency.get('symbol'), @get('amount')
      amount = invoiceCurrency.toCurrency currencyTo.get('symbol'), amount
      @set 'amount', amount.round(2)

    @set 'currency', currencyTo

`export default Payment`
