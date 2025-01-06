resource "aws_acm_certificate" "cert" {
  domain_name       = var.cf_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = "ssl-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = trimsuffix(each.value.record, ".")
  type    = each.value.type
  ttl     = 1
  proxied = false
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
}