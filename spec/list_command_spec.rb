# frozen_string_literal: true

require "spec_helper"

describe Bundle::Commands::List do
  before do
    allow_any_instance_of(IO).to receive(:puts)
  end

  context "outputs dependencies to stdout" do
    before do
      allow(ARGV).to receive(:value).and_return(nil)
      allow_any_instance_of(Pathname).to receive(:read)
        .and_return("tap 'phinze/cask'\nbrew 'mysql', conflicts_with: ['mysql56']\ncask 'google-chrome'\nmas '1Password', id: 443987910")
    end

    types_and_deps = {
      "--taps" => "phinze/cask",
      "--brews" => "mysql",
      "--casks" => "google-chrome",
      "--mas" => "1Password",
    }

    after do
      types_and_deps.each_key do |option|
        ARGV.delete option if ARGV.include? option
      end
    end

    it "only shows brew deps when no options are passed" do
      expect { described_class.run }.to output("mysql\n").to_stdout
    end

    context "limiting when certain options are passed" do
      combinations = 1.upto(types_and_deps.length).flat_map do |i|
        types_and_deps.keys.combination(i).take((1..types_and_deps.length).inject(:*) || 1)
      end.sort

      combinations.each do |options_list|
        words = options_list.map { |type| type[2..-1] }.join(" and ")
        opts = options_list.join(" and ")
        verb = options_list.length == 1 && "is" || "are"
        it "shows only #{words} when #{opts} #{verb} passed" do
          options_list.each { |opt| ARGV << opt }
          expected = options_list.map { |opt| types_and_deps[opt] }.join("\n")
          expect { described_class.run }.to output("#{expected}\n").to_stdout
        end
      end
    end
  end
end
