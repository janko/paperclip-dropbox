require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/strip"

module Paperclip
  module Storage
    module Dropbox
      class PathGenerator
        def initialize(attachment, attachment_options)
          @attachment = attachment
          @attachment_options = attachment_options
        end

        def generate(style)
          path = if normal_path_style?
                   generate_from_string(style)
                 else
                   generate_from_proc(style)
                 end
          path
        end

        private

        def normal_path_style?
          @attachment_options[:path].present?
        end

        def generate_from_string(style)
          @attachment_options[:interpolator].interpolate(@attachment.send(:path_option), @attachment, style)
        end

        def generate_from_proc(style)
          path = @attachment.instance.instance_exec(style, &file_path_proc)
          style_suffix = (style != @attachment.default_style ? "_#{style}" : "")

          extension = File.extname(@attachment.original_filename)
          if extension.present? and path =~ /#{extension}$/
            path.sub(extension, style_suffix + extension)
          else
            path + style_suffix
          end
        end

        # Oh my god, this is so ugly, why did I do ever do this? Ah, well, If nothing,
        # it demonstrates what kind of evil things you can do in Ruby :)
        def file_path_proc
          return @attachment_options[:dropbox_options][:path] if @attachment_options[:dropbox_options][:path]

          if @attachment_options[:dropbox_options][:unique_filename]
            eval %(proc { |style| "\#{ActiveModel::Naming.param_key(self.class)}_\#{id}_\#{#{@attachment.name}.name}" })
          else
            eval %(proc { |style| #{@attachment.name}.original_filename })
          end
        end
      end
    end
  end
end
