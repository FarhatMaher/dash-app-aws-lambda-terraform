resource "aws_ecr_repository" "ecr_repo" {
  name                 = "dash-app-ecr-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
