`import { test, moduleForModel } from 'ember-qunit'`

moduleForModel 'address', {
  # Specify the other units that are required for this test.
  needs: []
}

test 'it exists', (assert) ->
  model = @subject()
  assert.ok !!model

test 'method - recordIsEmpty', ->
  expect(2)
  store = @store()

  Em.run ->
    address = store.createRecord 'address'
    equal address.recordIsEmpty(), true, "the recordIsEmpty method should return true is address is empty"

    address.set 'country', 'France'
    equal address.recordIsEmpty(), false, "the recordIsEmpty method should return false is address isn't empty"

test 'method - dumpDatafrom', ->
  expect(10)
  store = @store()

  Em.run ->
    address = store.createRecord 'address'
    address.setProperties
      type: 'HOME'
      postofficeBox: 'postofficeBox'
      streetAddress: 'streetAddress'
      extendedAddress: 'extendedAddress'
      postalCode: 'postalCode'
      city: 'city'
      state: 'state'
      country: 'country'
      label: 'label'
      geoPoint: 'geoPoint'

    newAddress = store.createRecord 'address'
    newAddress.dumpDataFrom address

    equal newAddress.get('type'), 'HOME', "address and newAddress type should be the same"
    equal newAddress.get('postofficeBox'), 'postofficeBox', "address and newAddress postofficeBox should be the same"
    equal newAddress.get('streetAddress'), 'streetAddress', "address and newAddress streetAddress should be the same"
    equal newAddress.get('extendedAddress'), 'extendedAddress', "address and newAddress extendedAddress should be the same"
    equal newAddress.get('postalCode'), 'postalCode', "address and newAddress postalCode should be the same"
    equal newAddress.get('city'), 'city', "address and newAddress city should be the same"
    equal newAddress.get('state'), 'state', "address and newAddress state should be the same"
    equal newAddress.get('country'), 'country', "address and newAddress country should be the same"
    equal newAddress.get('label'), 'label', "address and newAddress label should be the same"
    equal newAddress.get('geoPoint'), 'geoPoint', "address and newAddress geoPoint should be the same"

test 'property - type', ->
  expect(1)
  store = @store()

  Em.run ->
    address = store.push 'address', {id: 1}

    equal address.get('type'), 'WORK', "type default value should be 'WORK'"
