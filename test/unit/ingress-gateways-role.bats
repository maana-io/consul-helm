#!/usr/bin/env bats

load _helpers

@test "ingressGateways/Role: disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ingressGateways/Role: enabled with ingressGateways, connectInject and client.grpc enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      . | tee /dev/stderr |
      yq -s 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "ingressGateways/Role: rules for PodSecurityPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      --set 'global.enablePodSecurityPolicies=true' \
      . | tee /dev/stderr |
      yq -s -r '.[0].rules[0].resources[0]' | tee /dev/stderr)
  [ "${actual}" = "podsecuritypolicies" ]
}

@test "ingressGateways/Role: rules for global.acls.manageSystemACLs=true" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      --set 'global.acls.manageSystemACLs=true' \
      . | tee /dev/stderr |
      yq -s -r '.[0].rules[0]' | tee /dev/stderr)

  local actual=$(echo $object | yq -r '.resources[0]' | tee /dev/stderr)
  [ "${actual}" = "secrets" ]

  local actual=$(echo $object | yq -r '.resourceNames[0]' | tee /dev/stderr)
  [ "${actual}" = "ingress-gateway-ingress-gateway-acl-token" ]
}

@test "ingressGateways/Role: rules for ingressGateways .wanAddress.source=Service" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      . | tee /dev/stderr |
      yq -s -r '.[0].rules[0].resources[0]' | tee /dev/stderr)
  [ "${actual}" = "services" ]
}

@test "ingressGateways/Role: rules is empty if no ACLs, PSPs and ingressGateways .source != Service" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      --set 'ingressGateways.gateways[0].name=ingress-gateway' \
      --set 'ingressGateways.gateways[0].wanAddress.source=NodeIP' \
      . | tee /dev/stderr |
      yq -s -r '.[0].rules' | tee /dev/stderr)
  [ "${actual}" = "[]" ]
}

@test "ingressGateways/Role: rules for ACLs, PSPs and ingress gateways" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      --set 'global.acls.manageSystemACLs=true' \
      --set 'global.enablePodSecurityPolicies=true' \
      . | tee /dev/stderr |
      yq -s -r '.[0].rules | length' | tee /dev/stderr)
  [ "${actual}" = "3" ]
}

@test "ingressGateways/Role: rules for ACLs, PSPs and ingress gateways with multiple gateways" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/ingress-gateways-role.yaml  \
      --set 'ingressGateways.enabled=true' \
      --set 'connectInject.enabled=true' \
      --set 'client.grpc=true' \
      --set 'global.acls.manageSystemACLs=true' \
      --set 'global.enablePodSecurityPolicies=true' \
      --set 'ingressGateways.gateways[0].name=gateway1' \
      --set 'ingressGateways.gateways[1].name=gateway2' \
      . | tee /dev/stderr |
      yq -s -r '.' | tee /dev/stderr)

  local actual=$(echo $object | yq -r '.[0].metadata.name' | tee /dev/stderr)
  [ "${actual}" = "gateway1" ]

  local actual=$(echo $object | yq -r '.[1].metadata.name' | tee /dev/stderr)
  [ "${actual}" = "gateway2" ]

  local actual=$(echo $object | yq '.[0].rules | length' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  local actual=$(echo $object | yq '.[1].rules | length' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  local actual=$(echo $object | yq '.[2] | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
