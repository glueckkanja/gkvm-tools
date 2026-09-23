variable "name" {
  type        = string
  description = "Name of the repository."
  nullable    = false
}

variable "description" {
  type        = string
  default     = null
  description = "Optional description shown on the repository page."
}

variable "visibility" {
  type        = string
  default     = "private"
  description = "Repository visibility: public, private or internal."
  nullable    = false

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "visibility must be public, private or internal."
  }
}
