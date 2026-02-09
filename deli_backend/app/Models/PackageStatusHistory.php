<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PackageStatusHistory extends Model
{
    public $timestamps = false;

    protected $table = 'package_status_history';

    protected $fillable = [
        'package_id',
        'status',
        'changed_by_user_id',
        'changed_by_type',
        'notes',
        'latitude',
        'longitude',
        'created_at',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'created_at' => 'datetime',
    ];

    /**
     * Additional attributes to include in JSON responses.
     *
     * - changed_by_name: Human-readable name of the user who changed the status
     */
    protected $appends = [
        'changed_by_name',
    ];

    // Relationships
    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by_user_id');
    }

    /**
     * Accessor for changed_by_name.
     *
     * This lets the API return the real user's display name directly
     * on each status history record, so the mobile apps don't need
     * to perform extra lookups.
     */
    public function getChangedByNameAttribute(): ?string
    {
        return $this->changedBy?->name;
    }
}
