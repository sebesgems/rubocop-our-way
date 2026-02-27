# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::OurWay::SpellControllerInheritance, :config do
  let(:config) do
    RuboCop::Config.new(
      'OurWay/SpellControllerInheritance' => {
        'Enabled' => true
      }
    )
  end

  context 'when controller is in spell directory' do
    let(:filename) { 'app/controllers/spell/tokens_controller.rb' }

    it 'flags controller inheriting from ApplicationController' do
      expect_offense(<<~RUBY, filename)
        class TokensController < ApplicationController
                                 ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
        end
      RUBY
    end

    it 'accepts controller inheriting from Sebes::SpellController' do
      expect_no_offenses(<<~RUBY, filename)
        class TokensController < Sebes::SpellController
        end
      RUBY
    end

    it 'accepts controller inheriting from SpellController shorthand' do
      expect_no_offenses(<<~RUBY, filename)
        class TokensController < SpellController
        end
      RUBY
    end
  end

  context 'when controller is in Spell module namespace' do
    let(:filename) { 'app/controllers/tokens_controller.rb' }

    it 'flags controller inheriting from ApplicationController' do
      expect_offense(<<~RUBY, filename)
        module Spell
          class TokensController < ApplicationController
                                   ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
          end
        end
      RUBY
    end

    it 'accepts controller inheriting from Sebes::SpellController' do
      expect_no_offenses(<<~RUBY, filename)
        module Spell
          class TokensController < Sebes::SpellController
          end
        end
      RUBY
    end

    it 'accepts controller inheriting from intermediate base that inherits from SpellController' do
      expect_no_offenses(<<~RUBY, filename)
        module Sebes
          class BaseController < SpellController
          end

          module Spell
            class TokensController < BaseController
            end
          end
        end
      RUBY
    end

    it 'flags controller with wrong parent that does not inherit from SpellController' do
      expect_offense(<<~RUBY, filename)
        module Sebes
          class BaseController < ApplicationController
          end

          module Spell
            class TokensController < BaseController
                                     ^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `BaseController`.
            end
          end
        end
      RUBY
    end
  end

  context 'when controller is in both spell directory and Spell namespace' do
    let(:filename) { 'app/controllers/spell/payments_controller.rb' }

    it 'flags controller inheriting from ApplicationController' do
      expect_offense(<<~RUBY, filename)
        module Spell
          class PaymentsController < ApplicationController
                                     ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
          end
        end
      RUBY
    end

    it 'accepts correct inheritance' do
      expect_no_offenses(<<~RUBY, filename)
        module Spell
          class PaymentsController < Sebes::SpellController
          end
        end
      RUBY
    end
  end

  context 'when controller is NOT in spell context' do
    let(:filename) { 'app/controllers/users_controller.rb' }

    it 'does not flag controller inheriting from ApplicationController' do
      expect_no_offenses(<<~RUBY, filename)
        class UsersController < ApplicationController
        end
      RUBY
    end

    it 'does not flag controller inheriting from any other base' do
      expect_no_offenses(<<~RUBY, filename)
        class UsersController < BaseController
        end
      RUBY
    end
  end

  context 'when file is not a controller' do
    let(:filename) { 'app/models/user.rb' }

    it 'does not flag non-controller classes' do
      expect_no_offenses(<<~RUBY, filename)
        class User < ApplicationRecord
        end
      RUBY
    end
  end

  context 'with namespaced controllers' do
    let(:filename) { 'app/controllers/spell/v1/tokens_controller.rb' }

    it 'flags namespaced controller with wrong parent' do
      expect_offense(<<~RUBY, filename)
        module Spell
          module V1
            class TokensController < ApplicationController
                                     ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
            end
          end
        end
      RUBY
    end

    it 'accepts namespaced controller with correct parent' do
      expect_no_offenses(<<~RUBY, filename)
        module Spell
          module V1
            class TokensController < Sebes::SpellController
            end
          end
        end
      RUBY
    end
  end

  context 'with engine controllers' do
    context 'when file is in engines spell directory' do
      let(:filename) { 'engines/paymentfarm/app/controllers/spell/purchases_controller.rb' }

      it 'flags engine controller inheriting from ApplicationController' do
        expect_offense(<<~RUBY, filename)
          class Spell::PurchasesController < ApplicationController
                                             ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
          end
        RUBY
      end

      it 'accepts engine controller inheriting from Sebes::SpellController' do
        expect_no_offenses(<<~RUBY, filename)
          class Spell::PurchasesController < Sebes::SpellController
          end
        RUBY
      end

      it 'accepts engine controller inheriting from ::Sebes::SpellController' do
        expect_no_offenses(<<~RUBY, filename)
          class Spell::PurchasesController < ::Sebes::SpellController
          end
        RUBY
      end
    end

    context 'when engine controller is in Spell module namespace' do
      let(:filename) { 'engines/paymentfarm/app/controllers/paymentfarm/purchases_controller.rb' }

      it 'flags engine controller in Spell namespace with wrong parent' do
        expect_offense(<<~RUBY, filename)
          module Paymentfarm
            module Spell
              class PurchasesController < ApplicationController
                                          ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
              end
            end
          end
        RUBY
      end

      it 'accepts engine controller in Spell namespace with correct parent' do
        expect_no_offenses(<<~RUBY, filename)
          module Paymentfarm
            module Spell
              class PurchasesController < Sebes::SpellController
              end
            end
          end
        RUBY
      end
    end

    context 'when engine controller is NOT in spell context' do
      let(:filename) { 'engines/yapily/app/controllers/yapily/transactions_controller.rb' }

      it 'does not flag engine controller outside spell context' do
        expect_no_offenses(<<~RUBY, filename)
          class Yapily::TransactionsController < ApplicationController
          end
        RUBY
      end

      it 'does not flag module form engine controller outside spell context' do
        expect_no_offenses(<<~RUBY, filename)
          module Yapily
            class TransactionsController < ApplicationController
            end
          end
        RUBY
      end
    end

    context 'when engine has both spell and non-spell controllers' do
      it 'only flags controllers in spell namespace' do
        filename = 'engines/walletto/app/controllers/walletto/spell/cards_controller.rb'
        expect_offense(<<~RUBY, filename)
          module Walletto
            module Spell
              class CardsController < ApplicationController
                                      ^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ApplicationController`.
              end
            end
          end
        RUBY
      end

      it 'does not flag non-spell controllers in same engine' do
        filename = 'engines/walletto/app/controllers/walletto/accounts_controller.rb'
        expect_no_offenses(<<~RUBY, filename)
          module Walletto
            class AccountsController < ApplicationController
            end
          end
        RUBY
      end
    end
  end

  context 'with routes-based spell scope detection' do
    let(:filename) { 'engines/blik/app/controllers/blik/purchases_controller.rb' }
    let(:routes_path) { 'engines/blik/config/routes.rb' }
    let(:routes_content) do
      <<~RUBY
        Blik::Engine.routes.draw do
          scope path: :spell do
            resources :purchases, only: [:create]
          end
        end
      RUBY
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(routes_path).and_return(true)
      allow(File).to receive(:read).with(routes_path).and_return(routes_content)
    end

    it 'flags controller routed under spell scope with wrong parent' do
      expect_offense(<<~RUBY, filename)
        class Blik::PurchasesController < ActionController::Base
                                          ^^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `ActionController::Base`.
        end
      RUBY
    end

    it 'accepts controller routed under spell scope with correct parent' do
      expect_no_offenses(<<~RUBY, filename)
        class Blik::PurchasesController < Sebes::SpellController
        end
      RUBY
    end

    context 'when controller is not in spell scope' do
      let(:routes_content) do
        <<~RUBY
          Blik::Engine.routes.draw do
            resources :purchases, only: [:create]
          end
        RUBY
      end

      it 'does not flag controller outside spell scope' do
        expect_no_offenses(<<~RUBY, filename)
          class Blik::PurchasesController < ActionController::Base
          end
        RUBY
      end
    end
  end

  context 'with cross-file inheritance chain' do
    let(:filename) { 'engines/blik/app/controllers/blik/purchases_controller.rb' }
    let(:routes_path) { 'engines/blik/config/routes.rb' }
    let(:abstract_controller_path) { 'engines/blik/app/controllers/api/sebes_abstract_controller.rb' }
    let(:routes_content) do
      <<~RUBY
        Blik::Engine.routes.draw do
          scope path: :spell do
            resources :purchases, only: [:create]
          end
        end
      RUBY
    end
    let(:abstract_controller_source) do
      <<~RUBY
        class Api::SebesAbstractController < Sebes::SpellController
          extend T::Sig
          extend T::Helpers

          include ::EngineLogTaggable
          include ::RollbarScoped

          abstract!
        end
      RUBY
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(routes_path).and_return(true)
      allow(File).to receive(:exist?).with(abstract_controller_path).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(routes_path).and_return(routes_content)
      allow(File).to receive(:read).with(abstract_controller_path).and_return(abstract_controller_source)
    end

    it 'accepts controller inheriting from intermediate class that inherits from SpellController' do
      expect_no_offenses(<<~RUBY, filename)
        class Blik::PurchasesController < Api::SebesAbstractController
        end
      RUBY
    end

    context 'when intermediate class does not inherit from SpellController' do
      let(:abstract_controller_source) do
        <<~RUBY
          class Api::SebesAbstractController < ActionController::Base
            extend T::Sig
            extend T::Helpers

            abstract!
          end
        RUBY
      end

      it 'flags controller with wrong inheritance chain' do
        expect_offense(<<~RUBY, filename)
            class Blik::PurchasesController < Api::SebesAbstractController
                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Controllers under the spell scope must inherit from `Sebes::SpellController`, not `Api::SebesAbstractController`.
          end
        RUBY
      end
    end
  end
end
