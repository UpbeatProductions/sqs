module Sqs
  class Response
    attr_reader :response, :xml

    def initialize(response)
      @response = response
      @xml      = response.body
    end

    def type
      @type ||= begin
        match = self.class.name.match("^Sqs::(.*)Response$")

        unless match
          raise "Response subclasses must have a name ending with Response"
        end

        match[1]
      end
    end

    def content
      xml.css("#{type}Response > #{type}Result")
    end

    def request_id
      xml.css("#{type}Response > ResponseMetadata > RequestId").text
    end

    def status
      response.status.to_i
    end

    def success?
      (200..299).include? status
    end
  end

  class QueueResponse < Response
    def queue_url
      content.css("QueueUrl").text.strip
    end
  end

  class CreateQueueResponse < QueueResponse
  end

  class GetQueueUrlResponse < QueueResponse
  end

  class ReceiveMessageResponse < Response
    def field(name)
      content.css("Message > #{name}").text.strip
    end

    def attribute(name)
      attribute = content.css("Message > Attribute").detect do |node|
        node.css("Name").text == name
      end

      attribute.parent.css("Value").text.strip
    end

    def attributes
      {
        :id   => field("MessageId"),
        :body => field("Body"),
        :receipt_handle => field("ReceiptHandle"),
      }
    end
  end

  class SendMessageResponse < Response
    def attributes
      { :id => content.css("MessageId").text.strip }
    end
  end
end
