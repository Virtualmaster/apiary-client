# encoding: utf-8
require 'rest_client'
require 'ostruct'
require 'json'

#TODO Dictionaries inclusion under scope of Apiary::Command::Compile#compile method
#require dictionaries
Dir[File.join('./apiary/dictionaries/**/*.rb')].each do |file|
  require File.join(file)
end
include Dictionaries

module Apiary
  module Command
    # Display preview of local blueprint file
    class Compile

      
      attr_reader :options

      # TODO: use OpenStruct to store @options
      def initialize(opts)
        @options = OpenStruct.new(opts)
        @options.path         ||= "apiary.apib"
        @options.api_host     ||= "api.apiary.io"
        @options.headers      ||= {:accept => "text/html", :content_type => "text/plain"}
        @options.port         ||= 8080
      end

      def self.execute(args)
        new(args).compile
      end

      def compile


        buffer = []
        header_file_name = 'header.apib'
        header_file_path = File.join('./apiary', header_file_name)

        if File.exists?(header_file_path)
          File.open(header_file_path).each_line do |line|
            buffer << line
          end
        end

        Dir['./apiary/**/*.apib'].delete_if{|f| f.include?(header_file_name)}.each do |file|
          if File.file?(file)
            File.open(file,'r').each_line do |line|
              dictionary_matcher = "*****"
              if line.include?(dictionary_matcher)
                dictionary_name = line.gsub(dictionary_matcher,'').strip
                module_name = dictionary_name.split('.')[0]
                method = dictionary_name.split('.')[1]
                directory = Kernel.const_get(module_name).send(method)

                if [Hash,Array].include?(directory.class)
                  output = JSON.pretty_generate(directory)
                else
                  output = directory
                end

                buffer << output
              else
                buffer << line
              end
            end
          end
        end

        #write compiled apiary file
        File.open('./apiary.apib','w') do |file|
          buffer.each do |line|
            file.puts line
          end
        end
      end
    end
  end
end
