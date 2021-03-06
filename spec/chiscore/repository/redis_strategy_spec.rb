require 'chiscore/repository/redis_strategy'

describe ChiScore::RedisStrategy do

  subject { described_class }
  let!(:now) { Time.now }

  before {
    subject.redis.select(14)
    Time.stub(:now) { now }
  }

  after { subject.redis.flushdb }

  it "sets an active team for a checkpoint" do
    subject.check_in!("checkpoint-id", "team-id")
    subject.active_for("checkpoint-id").should == ["team-id"]
  end

  it "saves the race's start time" do
    current_time = Time.now
    Time.stub(:now) { current_time }
    subject.save_race_start
    subject.fetch_race_start.should == current_time.to_i.to_s

    Time.stub(:now) { Time.now.to_i + 1000 }
    subject.save_race_start
    subject.fetch_race_start.should == current_time.to_i.to_s
  end

  it "removes an active team from a checkpoint on checkout" do
    subject.check_in!("checkpoint-id", "team-id")
    subject.check_out!("checkpoint-id", "team-id")
    subject.active_for("checkpoint-id").should be_empty
  end

  it "gets a time for a given record" do
    subject.check_in!("checkpoint-id", "team-id")
    subject.time_for("checkpoint-id", "team-id").should be > (25*60)-5
  end

  it "returns -1 for a time that doesn't exist" do
    subject.time_for("checkpoint-id", "team-id").should == -2
  end

  it "gets checkins for checkpoints" do
    subject.check_in!("checkpoint-id", "team-id1")
    subject.check_in!("checkpoint-id", "team-id2")

    subject.checkins_for("checkpoint-id").should == {
      "team-id1" => now.to_i,
      "team-id2" => now.to_i
    }
  end

  it "gets checkouts for checkpoints" do
    subject.check_out!("checkpoint-id", "team-id1")
    subject.check_out!("checkpoint-id", "team-id2")

    subject.checkouts_for("checkpoint-id").should == {
      "team-id1" => now.to_i,
      "team-id2" => now.to_i
    }
  end

  it "gets the time for the checkout for a given record" do
    subject.check_out!("checkpoint-id", "team-id1")
    time = subject.team_checkout("checkpoint-id", "team-id1")
    expect(time).to eq Time.now.to_i
  end

  it "destroys a checkin and returns -2 for times that don't exist" do
    subject.check_in!("checkpoint-id", "team-id1")
    time = subject.time_for("checkpoint-id", "team-id1")
    expect(time).to_not eq -2
    subject.destroy_checkin!("checkpoint-id", "team-id1")
    time = subject.time_for("checkpoint-id", "team-id1")
    expect(time).to eq -2
  end
end
