#!/usr/bin/env ruby
# schema2ldif.rb
# Copyright (c) 2015 IGARASHI Makoto (raccy)
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

if RUBY_VERSION.split(".")[0].to_i < 2
  warn "Ruby version must be over 2.0.0."
  exit 2
end

require "pathname"

def add_entry(io, entry, line_length = 78)
  entry = entry.gsub(/\s+/, " ")
  if entry.size <= 78
    io.puts entry
  else
    dummy, first, entry = entry.split(/^(.{1,#{line_length}})/)
    io.puts first
    entry.scan(/.{1,#{line_length - 1}}/) do |remain_line|
      io.write " "
      io.puts remain_line
    end
  end
end

def schema2ldif(name, schema, ldif, line_length = 78)
  schema.open("r") do |schema_io|
    ldif.open("w") do |ldif_io|
      ldif_io.write <<EOH
dn: cn=#{name},cn=schema,cn=config
objectClass: olcSchemaConfig
cn: #{name}
EOH
     entry = nil
      while line = schema_io.gets
        line.chomp!
        line.sub!(/\#.*$/, '')
        line.rstrip!
        next if line.empty?
        case line
        when /^attributetype(\s.*)?$/i
          if entry
            add_entry(ldif_io, entry, line_length)
          end
          entry = ""
          entry << "olcAttributeTypes: "
          if $1
            entry << $1
          end
        when /^objectclass(\s.*)?$/i
          if entry
            add_entry(ldif_io, entry, line_length)
          end
          entry = ""
          entry << "olcObjectClasses: "
          if $1
            entry << $1
          end
        when /^(\s.*)$/i
          fail "not start line: #{line}" if entry.nil?
          entry << $1
        else
          fail "invalid line: #{line}"
        end
      end
      if entry
        add_entry(ldif_io, entry, line_length)
      end
    end
  end
  return true
end

if $0 == __FILE__
  if ARGV.size < 1
    warn "Usage: #{$0} schema_files ..."
    exit 1
  end
  ARGV.each do |schema_file|
    print "convert: #{schema_file}"
    $stdout.flush
    schema_path = Pathname(schema_file)
    p schema_path
    if not schema_path.file?
      puts "-> NG: schema file not found."
      next
    end
    name = schema_path.basename('.*').to_s
    ldif_path = schema_path.dirname + (name + ".ldif")
    if ldif_path.exist?
      warn "ldif file exists, overwrite!"
      # puts "-> NG: ldif file exists."
      # next
    end
    begin
      if schema2ldif(name, schema_path, ldif_path)
        puts "-> OK"
      else
        puts "-> NG"
      end
    rescue => e
      puts "->ERR: #{e.to_s}"
    end
  end
end

