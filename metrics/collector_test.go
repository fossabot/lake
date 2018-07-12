package metrics

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMetricsPersist(t *testing.T) {
	entity := NewMetrics()

	t.Log("MessageEgress properly updates egress messages")
	{
		require.Equal(t, int64(0), entity.messageEgress.Count())

		for i := 1; i <= 10000; i++ {
			entity.MessageEgress(int64(1))
		}

		assert.Equal(t, int64(10000), entity.messageEgress.Count())

		entity.messageEgress.Clear()
		assert.Equal(t, int64(0), entity.messageEgress.Count())
	}

	t.Log("MessageIngress properly updates ingress messages")
	{
		require.Equal(t, int64(0), entity.messageIngress.Count())

		for i := 1; i <= 10000; i++ {
			entity.MessageIngress(int64(1))
		}

		assert.Equal(t, int64(10000), entity.messageIngress.Count())

		entity.messageIngress.Clear()
		assert.Equal(t, int64(0), entity.messageIngress.Count())
	}
}
