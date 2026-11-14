package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestReadVersions(t *testing.T) {
	path := filepath.Join(t.TempDir(), "versions.env")
	if err := os.WriteFile(path, []byte("# releases\nsb-manager=v1.2.3\nplugin-example=v2.0.0\n"), 0600); err != nil {
		t.Fatal(err)
	}
	versions, err := readVersions(path)
	if err != nil {
		t.Fatal(err)
	}
	if versions["sb-manager"] != "v1.2.3" || versions["plugin-example"] != "v2.0.0" {
		t.Fatalf("versions = %#v", versions)
	}
}

func TestInspectRequiresSerializedSetup(t *testing.T) {
	path := filepath.Join(t.TempDir(), "component")
	script := "#!/bin/sh\nprintf '%s\\n' '{\"id\":\"plugin-example\",\"kind\":\"plugin\",\"contractVersion\":1}'\n"
	if err := os.WriteFile(path, []byte(script), 0700); err != nil {
		t.Fatal(err)
	}
	_, err := inspect(path)
	if err == nil || !strings.Contains(err.Error(), "no serialized setup") {
		t.Fatalf("inspect() = %v, want missing setup error", err)
	}
}

func TestInspectReadsComponentIdentityAndSetup(t *testing.T) {
	path := filepath.Join(t.TempDir(), "component")
	script := "#!/bin/sh\nprintf '%s\\n' '{\"id\":\"plugin-example\",\"kind\":\"plugin\",\"contractVersion\":1,\"dependsOn\":[\"storage\"],\"setup\":{\"mode\":\"selectable\",\"category\":\"Example\"}}'\n"
	if err := os.WriteFile(path, []byte(script), 0700); err != nil {
		t.Fatal(err)
	}
	got, err := inspect(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.ID != "plugin-example" || got.Kind != "plugin" || len(got.DependsOn) != 1 {
		t.Fatalf("inspect() = %#v", got)
	}
}
