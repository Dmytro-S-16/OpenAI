import Foundation

public struct ThreadAddMessageQuery: Equatable, Codable, Sendable {
	public let role: ChatQuery.ChatCompletionMessageParam.Role
	public let content: Content

	public enum Content: Equatable, Codable, Sendable {
		case string(String)
		case contentArray([ContentPart])

		public init(from decoder: any Decoder) throws {
			let container = try decoder.singleValueContainer()
			if let string = try? container.decode(String.self) {
				self = .string(string)
			} else if let array = try? container.decode([ContentPart].self) {
				self = .contentArray(array)
			} else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Content must be either a String or an array of ContentPart"
				)
			}
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.singleValueContainer()
			switch self {
			case .string(let string):
				try container.encode(string)
			case .contentArray(let array):
				try container.encode(array)
			}
		}
	}

	public enum ContentPart: Equatable, Codable, Sendable {
		case text(text: String)
		case imageFile(fileId: String)
		case imageURL(url: String)

		enum CodingKeys: String, CodingKey {
			case type
			case text
			case imageFile = "image_file"
			case imageURL = "image_url"
		}

		enum ImageFileCodingKeys: String, CodingKey {
			case fileId = "file_id"
		}

		enum ImageURLCodingKeys: String, CodingKey {
			case url
		}

		enum ContentType: String, Codable {
			case text
			case imageFile = "image_file"
			case imageURL = "image_url"
		}

		public init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let type = try container.decode(ContentType.self, forKey: .type)

			switch type {
			case .text:
				let text = try container.decode(String.self, forKey: .text)
				self = .text(text: text)
			case .imageFile:
				let imageFileContainer = try container.nestedContainer(keyedBy: ImageFileCodingKeys.self, forKey: .imageFile)
				let fileId = try imageFileContainer.decode(String.self, forKey: .fileId)
				self = .imageFile(fileId: fileId)
			case .imageURL:
				let imageURLContainer = try container.nestedContainer(keyedBy: ImageURLCodingKeys.self, forKey: .imageURL)
				let url = try imageURLContainer.decode(String.self, forKey: .url)
				self = .imageURL(url: url)
			}
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			switch self {
			case .text(let text):
				try container.encode(ContentType.text, forKey: .type)
				try container.encode(text, forKey: .text)
			case .imageFile(let fileId):
				try container.encode(ContentType.imageFile, forKey: .type)
				var imageFileContainer = container.nestedContainer(keyedBy: ImageFileCodingKeys.self, forKey: .imageFile)
				try imageFileContainer.encode(fileId, forKey: .fileId)
			case .imageURL(let url):
				try container.encode(ContentType.imageURL, forKey: .type)
				var imageURLContainer = container.nestedContainer(keyedBy: ImageURLCodingKeys.self, forKey: .imageURL)
				try imageURLContainer.encode(url, forKey: .url)
			}
		}
	}

	public init(
		role: ChatQuery.ChatCompletionMessageParam.Role,
		content: String,
		fileIds: [String]? = nil
	) {
		self.role = role
		if let fileIds, !fileIds.isEmpty {
			var contentParts: [ContentPart] = []
			contentParts.append(.text(text: content))
			for fileId in fileIds {
				contentParts.append(.imageFile(fileId: fileId))
			}
			self.content = .contentArray(contentParts)
		} else {
			self.content = .string(content)
		}
	}

	// New initializer with content array
	public init(
		role: ChatQuery.ChatCompletionMessageParam.Role,
		content: [ContentPart]
	) {
		self.role = role
		self.content = .contentArray(content)
	}
}
