require 'csv'
require 'oj'
require 'awesome_print'

class SummaryReport
	OPERATIONS = ['Added', 'Removed']
	def self.run(input_filepath, output_filepath)
		summary_hash = parse_json(input_filepath)
		write_csv(output_filepath, summary_hash)
	end

	def self.write_csv(filepath, summary_hash)
		time = Time.now
		puts "Begin writing csv"
		CSV.open(filepath, 'w+') do |csv|
		  csv << ['feature_type', 'country_changed', 'ending_sentence']
		  summary_hash.each do |feature_type, summary_sentences|
		  	summary_sentences.each do |summary_sentence|
		  		csv << [
		  			feature_type,
		  			summary_sentence[:summary], # join this into 1 string
		  			summary_sentence[:ending_sentence], # join this into 1 string
		  		]
		  	end
		  end
		end
		puts "End writing csv, #{Time.now - time}s"
	end

	def self.parse_json(filepath)
		time = Time.now
		puts "Begin parse json"
		doc_json = Oj.load_file(filepath); nil
		feature_type_hash = doc_json['docs'].each_with_object({}) do |item, hash|
			delta_item = item['delta']
			domain = delta_item['domain']
			delta_type = delta_item['deltaType']
			delta_value = delta_item['deltaValue']
			delta_percentage = delta_item['deltaPercentage']
			attribute_value = delta_item['attributeValue']
			protopath = delta_item['protopath']
			feature_type = delta_item['featureType']
			if protopath == 'FeatureProto'
				delta_percentage_in_text = "#{(delta_percentage).round(2)}%"

				normalized_action = normalize_action(delta_type, delta_value)
				ending_sentence = append_ending_sentence(normalized_action, attribute_value, protopath)

				hash[feature_type] ||= []
				hash[feature_type] << {
					summary: "#{normalized_action} in #{domain}(#{delta_percentage_in_text})", #join this into 1 string
					ending_sentence: ending_sentence, #join this into 1 string
				}
			end
		end
		puts "End parse json, #{Time.now - time}s"
		feature_type_hash
	end

	def self.normalize_action(delta_type, delta_value)
		return "#{delta_type} #{delta_value}" if OPERATIONS.include?(delta_type)
		return "+#{delta_value}" if delta_type == 'Increased'
		"#{delta_value}"
	end

	def self.append_ending_sentence(normalized_action, attribute_value, protopath)
		has_operation = OPERATIONS.any? { |operation| normalized_action.include?(operation) }
		return '' if !has_operation
		action_in_lowercase = normalized_action.include?('Added') ? 'newly added' : 'entirely deleted'
		"#{protopath} attribute value #{attribute_value} #{action_in_lowercase}"
	end
end

SummaryReport.run('outputt.json', 'output2.csv')
