#!/usr/bin/env bash
kubectl port-forward -n istio-system service/grafana 3000:3000
