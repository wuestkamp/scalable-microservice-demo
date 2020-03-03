package main

import (
	"encoding/json"
	"fmt"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"os"
	"os/signal"
	"runtime"
	"syscall"
	"time"
)

type UserApproveEvent struct {
	Uuid string		`json:"uuid"`
	Type string		`json:"type"`
	State string	`json:"state"`
	Data struct {
		Name string			`json:"name"`
		CreatedAt string	`json:"createdAt"`
		Uuid string			`json:"uuid"`
		Approved string		`json:"approved"`
	} `json:"data"`
	Response struct {
		State string `json:"state"`
	} `json:"response"`
}

func main() {
	bootstrapServers := os.Getenv("KAFKA_BOOTSTRAP_SERVERS")
	saslUsername := os.Getenv("KAFKA_SASL_USERNAME")
	saslPassword := os.Getenv("KAFKA_SASL_PASSWORD")

	topicUserApprove := "user-approve"
	topicUserApproveResponse := "user-approve-response"

	// Create Consumer instance
	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": bootstrapServers,
		"sasl.mechanisms":   "PLAIN",
		"security.protocol": "SASL_SSL",
		"sasl.username":     saslUsername,
		"sasl.password":     saslPassword,
		"group.id":          "user-approval-service",
		"auto.offset.reset": "earliest"})
	if err != nil {
		fmt.Printf("Failed to create consumer: %s", err)
		os.Exit(1)
	}

	// Create Producer instance
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": bootstrapServers,
		"sasl.mechanisms":   "PLAIN",
		"security.protocol": "SASL_SSL",
		"sasl.username":     saslUsername,
		"sasl.password":     saslPassword})
	if err != nil {
		fmt.Printf("Failed to create producer: %s", err)
		os.Exit(1)
	}

	// Subscribe to topicUserApprove
	err = c.SubscribeTopics([]string{topicUserApprove}, nil)
	// Set up a channel for handling Ctrl-C, etc
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	// Process messages
	run := true
	for run == true {
		select {
		case sig := <-sigchan:
			fmt.Printf("Caught signal %v: terminating\n", sig)
			run = false
		default:
			msg, err := c.ReadMessage(100 * time.Millisecond)
			if err != nil {
				// Errors are informational and automatically handled by the consumer
				continue
			}
			recordKey := string(msg.Key)
			recordValue := msg.Value

			var data UserApproveEvent

			err = json.Unmarshal(recordValue, &data)
			if err != nil {
				fmt.Printf("Failed to decode JSON at offset %d: %v", msg.TopicPartition.Offset, err)
				continue
			}

			fmt.Printf("Consumed record with key %s and value %s\n", recordKey, recordValue)

			//fmt.Printf("Going to use CPU for: %d ms\n", milliSeconds)
			//milliSeconds := rand.Intn(1000)
			//cpuUsage(milliSeconds)

			milliSeconds := 200 // + rand.Intn(300)
			fmt.Printf("Going to sleep for: %d ms\n", milliSeconds)
			time.Sleep(time.Duration(milliSeconds) * time.Millisecond)

			data.Data.Approved = "false"
			recordValueSend, _ := json.Marshal(data)

			fmt.Printf("Preparing to produce record: %s\t%s\n", recordKey, recordValueSend)

			_ = p.Produce(&kafka.Message{
				TopicPartition: kafka.TopicPartition{Topic: &topicUserApproveResponse, Partition: kafka.PartitionAny},
				Key:            []byte(recordKey),
				Value:          []byte(recordValueSend),
			}, nil)

			fmt.Printf("Produced record with key %s and value %s\n", recordKey, recordValueSend)
		}
	}

	fmt.Printf("Closing\n")
	_ = c.Close()
	p.Close()
}

func cpuUsage(milliSeconds int) {
	n := runtime.NumCPU()
	runtime.GOMAXPROCS(n)

	quit := make(chan bool)

	for i := 0; i < n; i++ {
		go func() {
			for {
				select {
				case <-quit:
					return
				default:
				}
			}
		}()
	}

	time.Sleep(time.Duration(milliSeconds) * time.Millisecond)
	for i := 0; i < n; i++ {
		quit <- true
	}
}
