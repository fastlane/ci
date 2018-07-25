# Notifications are taken from rails/active_support/notification.
# http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html
#
# Copyright (c) 2005-2018 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# frozen_string_literal: true

require "mutex_m"
require "concurrent/map"

module FastlaneCI
  ##
  # a simple Notification pub/sub system, taken from ActiveSupport
  module Notifications
    # This is a default queue implementation that ships with Notifications.
    # It just pushes events to all registered log subscribers.
    #
    # This class is thread safe. All methods are reentrant.
    class Fanout
      include Mutex_m

      def initialize
        @subscribers = []
        @listeners_for = Concurrent::Map.new
        super
      end

      def subscribe(pattern = nil, block = Proc.new)
        subscriber = Subscribers.new(pattern, block)
        synchronize do
          @subscribers << subscriber
          @listeners_for.clear
        end
        subscriber
      end

      def unsubscribe(subscriber_or_name)
        synchronize do
          case subscriber_or_name
          when String
            @subscribers.reject! { |s| s.matches?(subscriber_or_name) }
          else
            @subscribers.delete(subscriber_or_name)
          end

          @listeners_for.clear
        end
      end

      def start(name, id, payload)
        listeners_for(name).each { |s| s.start(name, id, payload) }
      end

      def finish(name, id, payload, listeners = listeners_for(name))
        listeners.each { |s| s.finish(name, id, payload) }
      end

      ##
      # this is a modification of
      # https://github.com/rails/rails/blob/91ae6531976d0d2e7690bde0c1d5e6cc651f2578/activesupport/lib/active_support/notifications/fanout.rb#L51
      # so that we can also just provide a subscriber.
      #
      # We can also subclass the original implementation if we need to vendor it, or pull in activesupport
      def publish(name: nil, subscriber: nil, payload: {})
        if name
          listeners_for(name).each { |s| s.publish(name, payload) }
        end

        if subscriber
          subscriber.publish(subscriber.object_id, payload)
        end
      end

      def listeners_for(name)
        # this is correctly done double-checked locking (Concurrent::Map's lookups have volatile semantics)
        @listeners_for[name] || synchronize do
          # use synchronisation when accessing @subscribers
          @listeners_for[name] ||= @subscribers.select { |s| s.subscribed_to?(name) }
        end
      end

      def listening?(name)
        listeners_for(name).any?
      end

      # This is a sync queue, so there is no waiting.
      def wait
      end

      module Subscribers # :nodoc:
        def self.new(pattern, listener)
          if listener.respond_to?(:start) && listener.respond_to?(:finish)
            subscriber = Evented.new(pattern, listener)
          else
            subscriber = Timed.new(pattern, listener)
          end

          if pattern
            subscriber
          else
            AllMessages.new(subscriber)
          end
        end

        class Evented #:nodoc:
          def initialize(pattern, delegate)
            @pattern = pattern
            @delegate = delegate
            @can_publish = delegate.respond_to?(:publish)
          end

          def publish(name, *args)
            if @can_publish
              @delegate.publish(name, *args)
            end
          end

          def start(name, id, payload)
            @delegate.start(name, id, payload)
          end

          def finish(name, id, payload)
            @delegate.finish(name, id, payload)
          end

          # rubocop:disable Style/CaseEquality
          def subscribed_to?(name)
            @pattern === name
          end

          def matches?(name)
            @pattern && @pattern === name
          end
          # rubocop:enable Style/CaseEquality
        end

        class Timed < Evented # :nodoc:
          def publish(name, *args)
            @delegate.call(name, *args)
          end

          def start(name, id, payload)
            timestack = Thread.current[:_timestack] ||= []
            timestack.push(Time.now)
          end

          def finish(name, id, payload)
            timestack = Thread.current[:_timestack]
            started = timestack.pop
            @delegate.call(name, started, Time.now, id, payload)
          end
        end

        class AllMessages # :nodoc:
          def initialize(delegate)
            @delegate = delegate
          end

          def start(name, id, payload)
            @delegate.start(name, id, payload)
          end

          def finish(name, id, payload)
            @delegate.finish(name, id, payload)
          end

          def publish(name, *args)
            @delegate.publish(name, *args)
          end

          def subscribed_to?(name)
            true
          end

          alias matches? ===
        end
      end
    end

    class << self
      attr_accessor :notifier

      def publish(name, *args)
        notifier.publish(name, *args)
      end

      def subscribe(*args, &block)
        notifier.subscribe(*args, &block)
      end

      def subscribed(callback, *args, &block)
        subscriber = subscribe(*args, &callback)
        yield
      ensure
        unsubscribe(subscriber)
      end

      def unsubscribe(subscriber_or_name)
        notifier.unsubscribe(subscriber_or_name)
      end
    end

    self.notifier = Fanout.new
  end
end
