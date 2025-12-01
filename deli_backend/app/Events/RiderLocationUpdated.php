<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RiderLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $riderId;
    public $latitude;
    public $longitude;
    public $packageId;
    public $lastUpdate;

    /**
     * Create a new event instance.
     */
    public function __construct($riderId, $latitude, $longitude, $packageId = null)
    {
        $this->riderId = $riderId;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
        $this->packageId = $packageId;
        $this->lastUpdate = now()->toIso8601String();
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // Office can always see all riders (private channel with authorization)
        $channels = [
            new PrivateChannel('office.riders.locations'),
        ];

        // Merchant can see rider location only when package status = on_the_way
        if ($this->packageId) {
            $package = \App\Models\Package::find($this->packageId);
            if ($package && $package->status === 'on_the_way') {
                $channels[] = new PrivateChannel('merchant.package.' . $this->packageId . '.location');
            }
        }

        return $channels;
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'rider.location.updated';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'rider_id' => $this->riderId,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'package_id' => $this->packageId,
            'last_update' => $this->lastUpdate,
        ];
    }
}
