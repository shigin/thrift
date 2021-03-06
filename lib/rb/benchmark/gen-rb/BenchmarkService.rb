#
# Autogenerated by Thrift
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#

require 'thrift'
require 'thrift/protocol'
require File.dirname(__FILE__) + '/Benchmark_types'

    module ThriftBenchmark
      module BenchmarkService
        class Client
          include Thrift::Client

          def fibonacci(n)
            send_fibonacci(n)
            return recv_fibonacci()
          end

          def send_fibonacci(n)
            send_message('fibonacci', Fibonacci_args, :n => n)
          end

          def recv_fibonacci()
            result = receive_message(Fibonacci_result)
            return result.success unless result.success.nil?
            raise Thrift::ApplicationException.new(Thrift::ApplicationException::MISSING_RESULT, 'fibonacci failed: unknown result')
          end

        end

        class Processor
          include Thrift::Processor

          def process_fibonacci(seqid, iprot, oprot)
            args = read_args(iprot, Fibonacci_args)
            result = Fibonacci_result.new()
            result.success = @handler.fibonacci(args.n)
            write_result(result, oprot, 'fibonacci', seqid)
          end

        end

        # HELPER FUNCTIONS AND STRUCTURES

        class Fibonacci_args
          include Thrift::Struct
          Thrift::Struct.field_accessor self, :n
          FIELDS = {
            1 => {:type => Thrift::Types::BYTE, :name => 'n'}
          }
        end

        class Fibonacci_result
          include Thrift::Struct
          Thrift::Struct.field_accessor self, :success
          FIELDS = {
            0 => {:type => Thrift::Types::I32, :name => 'success'}
          }
        end

      end

    end
