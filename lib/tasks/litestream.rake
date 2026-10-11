namespace :litestream do
  # Restores every database in config/litestream.yml that is missing locally
  # and has a replica. A database already on disk is left alone, so this is a
  # no-op on every ordinary deploy and only does work on a fresh volume.
  #
  # The gem's own restore task ignores the binary's exit status. This one calls
  # the binary directly and aborts on failure, because the next step,
  # db:prepare, would otherwise create empty databases in place of the lost
  # ones.
  desc "Restore any missing replicated database from Backblaze B2"
  task restore_missing: :environment do
    if ENV["LITESTREAM_REPLICA_BUCKET"].blank?
      puts "LITESTREAM_REPLICA_BUCKET is not set; skipping restore."
      next
    end

    Litestream::Commands.databases.each do |database|
      path = database["path"]
      restored = system(
        Litestream::Commands.executable, "restore",
        "-config", Litestream.config_path.to_s,
        "-if-db-not-exists", "-if-replica-exists",
        path
      )
      abort "Litestream restore failed for #{path}" unless restored
    end
  end
end
