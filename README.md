# delivery-sugar

Delivery Sugar is a library cookbook that includes a collection of helpful
sugars and custom resources that make creating build cookbooks for Chef
Delivery projects a delightful experience.

## Installation

If you are using Berkshelf, add `delivery-sugar` to your `Berksfile`:

    cookbook 'delivery-sugar'


## Usage

In order to use Delivery Sugar in your build cookbook recipes, you'll first
need to declare your dependency on it in your `metadata.rb`.

    depends 'delivery-sugar'

Declaring your dependency will automatically extend the Recipe DSL,
`Chef::Resource` and `Chef::Provider` with helpful methods. It will also
automatically make available the custom resources included with Delivery Sugar.

**There is no need to include Delivery Sugar in any of your recipes**

## API



## License & Authors
- Author:: Tom Duffield (<tom@chef.io>)
- Author:: Jon Anderson (<janderson@chef.io>)
- Author:: Matt Campbell (<mcampbell@chef.io>)
- Author:: Salim Afiune (<afiune@chef.io>)


```text
Copyright:: 2015 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
