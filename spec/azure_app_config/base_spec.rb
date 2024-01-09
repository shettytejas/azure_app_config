# frozen_string_literal: true

require "debug"
require "dotenv"

RSpec.describe AzureAppConfig::Base do
  before do
    Dotenv.load(".env.test")
  end

  describe "#all" do
    subject(:result) { described_class.instance.all(**params) }

    describe "without params" do
      let(:params) { {} }

      it "returns all flags" do
        VCR.use_cassette("all/without_params") do
          expect(result).to be_a Array
          expect(result.size).to be > 0

          expect(result.first.keys).to match_array %w[etag key label content_type value tags locked last_modified]
          expect(result.first["value"].keys).to match_array %w[conditions description enabled id]
        end
      end
    end

    describe "with name param" do
      describe "as string" do
        let(:params) do
          {
            name: "SNA.Example2*"
          }
        end

        it "returns matching flags" do
          VCR.use_cassette("all/with_name_param_as_string") do
            expect(result).to be_a Array

            expect(result.size).to eq 11
            expect(result.map { |r| r["value"]["id"] }).to(be_all { |id| id.start_with?(params[:name].chomp("*")) })
          end
        end
      end

      describe "as array" do
        let(:params) do
          {
            name: ["SNA.Example2", "SNA.Example3"]
          }
        end

        it "returns matching flags" do
          VCR.use_cassette("all/with_name_param_as_array") do
            expect(result).to be_a Array

            expect(result.size).to eq 2
            expect(result.map { |r| r["value"]["id"] }).to match_array params[:name]
          end
        end
      end
    end

    describe "with label param" do
      describe "as string" do
        let(:params) do
          {
            label: "prod"
          }
        end

        it "returns matching flags" do
          VCR.use_cassette("all/with_label_param_as_string") do
            expect(result).to be_a Array

            expect(result.size).to eq 2
            expect(result.map { |r| r["label"] }.uniq).to match_array [params[:label]]
          end
        end
      end

      describe "as array" do
        let(:params) do
          {
            label: %w[prod test]
          }
        end

        it "returns matching flags" do
          VCR.use_cassette("all/with_label_param_as_array") do
            expect(result).to be_a Array

            expect(result.size).to eq 4
            expect(result.map { |r| r["label"] }.uniq).to match_array params[:label]
          end
        end
      end
    end

    describe "with both params" do
      let(:params) do
        {
          name: "SNA.*",
          label: "prod"
        }
      end

      it "returns matching flags" do
        VCR.use_cassette("all/with_both_params") do
          expect(result).to be_a Array

          expect(result.size).to eq 2
          expect(result.map { |r| r["label"] }.uniq).to match_array [params[:label]]
          expect(result.map { |r| r["value"]["id"] }).to(be_all { |id| id.start_with?(params[:name].chomp("*")) })
        end
      end
    end
  end

  describe "#fetch" do
    subject(:result) { described_class.instance.fetch(name, label: label) }

    describe "flag with name exists" do
      let(:name) { "SNA.Example2" }
      let(:label) { nil }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_without_label") do
          expect(result).to be_a Hash

          expect(result.keys).to match_array %w[etag key label content_type value tags locked last_modified]
          expect(result["value"].keys).to match_array %w[conditions description enabled id]
        end
      end
    end

    describe "flag with name doesn't exist" do
      let(:name) { "SNA.Example-1" }
      let(:label) { nil }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_without_label") do
          expect { result }.to raise_error AzureAppConfig::NotFoundError
        end
      end
    end

    describe "flag with name and label exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "prod" }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_and_label") do
          expect(result).to be_a Hash

          expect(result["label"]).to eq(label)
          expect(result["value"]["id"]).to eq("SNA.Example")
        end
      end
    end

    describe "flag with name and label doesn't exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "dev" }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_and_label") do
          expect { result }.to raise_error AzureAppConfig::NotFoundError
        end
      end
    end
  end

  describe "#enabled?" do
    subject(:result) { described_class.instance.enabled?(name, label: label) }

    describe "flag with name exists" do
      let(:name) { "SNA.Example2" }
      let(:label) { nil }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_without_label") do
          expect(result).to be true
        end
      end
    end

    describe "flag with name doesn't exist" do
      let(:name) { "SNA.Example-1" }
      let(:label) { nil }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_without_label") do
          expect(result).to be false
        end
      end
    end

    describe "flag with name and label exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "prod" }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_and_label") do
          expect(result).to be true
        end
      end
    end

    describe "flag with name and label doesn't exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "dev" }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_and_label") do
          expect(result).to be false
        end
      end
    end
  end

  describe "#disabled?" do
    subject(:result) { described_class.instance.disabled?(name, label: label) }

    describe "flag with name exists" do
      let(:name) { "SNA.Example2" }
      let(:label) { nil }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_without_label") do
          expect(result).to be false
        end
      end
    end

    describe "flag with name doesn't exist" do
      let(:name) { "SNA.Example-1" }
      let(:label) { nil }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_without_label") do
          expect(result).to be true
        end
      end
    end

    describe "flag with name and label exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "prod" }

      it "returns the flag" do
        VCR.use_cassette("fetch/with_existing_name_param_and_label") do
          expect(result).to be false
        end
      end
    end

    describe "flag with name and label doesn't exist" do
      let(:name) { "SNA.Example" }
      let(:label) { "dev" }

      it "raises error" do
        VCR.use_cassette("fetch/with_nonexisting_name_param_and_label") do
          expect(result).to be true
        end
      end
    end
  end

  describe "#keys" do
    subject(:result) { described_class.instance.keys(name: name) }

    describe "without name param" do
      let(:name) { nil }

      it "returns all keys" do
        VCR.use_cassette("keys/without_name_param") do
          expect(result).to be_a Array

          expect(result.size).to be > 0
        end
      end
    end

    describe "with name param" do
      describe "as string" do
        let(:name) { "SNA.Example2*" }

        it "returns matching keys" do
          VCR.use_cassette("keys/with_name_param_as_string") do
            expect(result).to be_a Array

            expect(result.size).to eq 11
            expect(result).to(be_all { |k| k.start_with?(name.chomp("*")) })
          end
        end
      end

      describe "as array" do
        let(:name) { ["SNA.Example2", "SNA.Example3"] }

        it "returns matching keys" do
          VCR.use_cassette("keys/with_name_param_as_array") do
            expect(result).to be_a Array

            expect(result.size).to eq 2
            expect(result).to(be_all { |k| name.include?(k) })
          end
        end
      end
    end
  end

  describe "#method_missing" do
    it "testing if all the above methods work as expected" do
      expect(described_class).to respond_to(:all)
      expect(described_class).to respond_to(:fetch)
      expect(described_class).to respond_to(:disabled?)
      expect(described_class).to respond_to(:enabled?)
      expect(described_class).to respond_to(:keys)

      expect(described_class).not_to respond_to(:some_wrong_method)
    end
  end
end
