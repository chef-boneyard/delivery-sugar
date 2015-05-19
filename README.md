delivery-sugar
==============

Delivery Sugar is a library cookbook that includes a collection of helpful
sugars and custom resources that make creating build cookbooks for Chef
Delivery projects a delightful experience.

Installation
------------

If you are using Berkshelf, add `delivery-sugar` to your `Berksfile`:

    cookbook 'delivery-sugar'


Usage
-----
In order to use Delivery Sugar in your build cookbook recipes, you'll first
need to declare your dependency on it in your `metadata.rb`.

    depends 'delivery-sugar'

Declaring your dependencing will automatically extend the Recipe DSL,
`Chef::Resource` and `Chef::Provider` with helpful methods. It will also
automatically make available the custom resources included with Delivery Sugar.

**There is no need to include Delivery Sugar in any of your recipes**
