SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: admin_broadcast_dismissals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_broadcast_dismissals (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    admin_broadcast_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_broadcast_dismissals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_broadcast_dismissals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_broadcast_dismissals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_broadcast_dismissals_id_seq OWNED BY public.admin_broadcast_dismissals.id;


--
-- Name: admin_broadcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_broadcasts (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    message text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone
);


--
-- Name: admin_broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_broadcasts_id_seq OWNED BY public.admin_broadcasts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: banned_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banned_accounts (
    id bigint NOT NULL,
    provider character varying NOT NULL,
    uid character varying NOT NULL,
    reason text,
    banned_until timestamp(6) without time zone,
    active boolean DEFAULT true NOT NULL,
    banned_by_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: banned_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.banned_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: banned_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.banned_accounts_id_seq OWNED BY public.banned_accounts.id;


--
-- Name: blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocks (
    id bigint NOT NULL,
    blocker_id bigint NOT NULL,
    blocked_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blocks_id_seq OWNED BY public.blocks.id;


--
-- Name: chat_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_rooms (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    private boolean DEFAULT false NOT NULL,
    user_a_id bigint,
    user_b_id bigint,
    ended_by_a boolean DEFAULT false NOT NULL,
    ended_by_b boolean DEFAULT false NOT NULL,
    rules text,
    origin character varying DEFAULT 'direct'::character varying NOT NULL
);


--
-- Name: chat_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_rooms_id_seq OWNED BY public.chat_rooms.id;


--
-- Name: comment_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_reactions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    comment_id bigint NOT NULL,
    emoji character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comment_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comment_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comment_reactions_id_seq OWNED BY public.comment_reactions.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    post_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    parent_id bigint
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: complaints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.complaints (
    id bigint NOT NULL,
    reported_by_id bigint NOT NULL,
    target_user_id bigint NOT NULL,
    description text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    post_id bigint
);


--
-- Name: complaints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.complaints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: complaints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.complaints_id_seq OWNED BY public.complaints.id;


--
-- Name: dashboard_widgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dashboard_widgets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    widget_type character varying NOT NULL,
    position_x integer DEFAULT 0 NOT NULL,
    position_y integer DEFAULT 0 NOT NULL,
    width integer DEFAULT 4 NOT NULL,
    height integer DEFAULT 3 NOT NULL,
    font_scale numeric(4,2) DEFAULT 1.0 NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dashboard_widgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dashboard_widgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboard_widgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dashboard_widgets_id_seq OWNED BY public.dashboard_widgets.id;


--
-- Name: dismissed_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dismissed_conversations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    chat_room_id bigint NOT NULL,
    dismissed_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dismissed_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dismissed_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dismissed_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dismissed_conversations_id_seq OWNED BY public.dismissed_conversations.id;


--
-- Name: escalations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escalations (
    id bigint NOT NULL,
    reported_by_id bigint NOT NULL,
    target_user_id bigint NOT NULL,
    description text NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: escalations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.escalations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: escalations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.escalations_id_seq OWNED BY public.escalations.id;


--
-- Name: feed_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feed_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    target_user_id bigint NOT NULL,
    preference character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: feed_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feed_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feed_preferences_id_seq OWNED BY public.feed_preferences.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    id bigint NOT NULL,
    follower_id bigint NOT NULL,
    followee_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follows_id_seq OWNED BY public.follows.id;


--
-- Name: github_repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.github_repositories (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying NOT NULL,
    full_name character varying NOT NULL,
    description text,
    primary_language character varying,
    stargazers_count integer DEFAULT 0,
    html_url character varying NOT NULL,
    repo_updated_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    visible_on_profile boolean DEFAULT true NOT NULL
);


--
-- Name: github_repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.github_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: github_repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.github_repositories_id_seq OWNED BY public.github_repositories.id;


--
-- Name: likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.likes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    likeable_type character varying NOT NULL,
    likeable_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.likes_id_seq OWNED BY public.likes.id;


--
-- Name: match_digests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_digests (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    matched_user_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    seen_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: match_digests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.match_digests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: match_digests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.match_digests_id_seq OWNED BY public.match_digests.id;


--
-- Name: message_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_reactions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message_id bigint NOT NULL,
    emoji character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_reactions_id_seq OWNED BY public.message_reactions.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_read boolean DEFAULT false,
    chat_room_id bigint NOT NULL,
    read_at timestamp(6) without time zone,
    edited_at timestamp(6) without time zone
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mutes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    muted_by_id bigint NOT NULL,
    reason text,
    muted_until timestamp(6) without time zone NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mutes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mutes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mutes_id_seq OWNED BY public.mutes.id;


--
-- Name: post_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_notifications (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    skill_id bigint,
    dismissed_at timestamp(6) without time zone,
    claimed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    seen_at timestamp(6) without time zone
);


--
-- Name: post_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_notifications_id_seq OWNED BY public.post_notifications.id;


--
-- Name: post_shares; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_shares (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: post_shares_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_shares_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_shares_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_shares_id_seq OWNED BY public.post_shares.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    title character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: posts_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_skills (
    post_id bigint NOT NULL,
    skill_id bigint NOT NULL
);


--
-- Name: profile_widgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_widgets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    widget_type character varying NOT NULL,
    position_x integer DEFAULT 0 NOT NULL,
    position_y integer DEFAULT 0 NOT NULL,
    width integer DEFAULT 4 NOT NULL,
    height integer DEFAULT 3 NOT NULL,
    font_scale numeric(4,2) DEFAULT 1.0 NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: profile_widgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_widgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_widgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_widgets_id_seq OWNED BY public.profile_widgets.id;


--
-- Name: ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ratings (
    id bigint NOT NULL,
    rater_id bigint NOT NULL,
    rated_user_id bigint NOT NULL,
    chat_room_id bigint NOT NULL,
    score integer NOT NULL,
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ratings_id_seq OWNED BY public.ratings.id;


--
-- Name: reposts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reposts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reposts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reposts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reposts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reposts_id_seq OWNED BY public.reposts.id;


--
-- Name: saved_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_posts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: saved_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.saved_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: saved_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.saved_posts_id_seq OWNED BY public.saved_posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: skill_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_aliases (
    id bigint NOT NULL,
    alias_name character varying NOT NULL,
    skill_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: skill_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skill_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skill_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skill_aliases_id_seq OWNED BY public.skill_aliases.id;


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    id bigint NOT NULL,
    category character varying,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    concurrency_key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    error text,
    job_id bigint NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    active_job_id character varying,
    arguments text,
    class_name character varying NOT NULL,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    finished_at timestamp(6) without time zone,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL,
    scheduled_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    hostname character varying,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    metadata text,
    name character varying NOT NULL,
    pid integer NOT NULL,
    supervisor_id bigint
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    task_key character varying NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    arguments text,
    class_name character varying,
    command character varying(2048),
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    key character varying NOT NULL,
    priority integer DEFAULT 0,
    queue_name character varying,
    schedule character varying NOT NULL,
    static boolean DEFAULT true NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    key character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    value integer DEFAULT 1 NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: user_skill_vectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_skill_vectors (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    generated_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    skill_distribution jsonb DEFAULT '{}'::jsonb NOT NULL,
    embedding_teach public.vector(512),
    embedding_learn public.vector(512)
);


--
-- Name: user_skill_vectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_skill_vectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_skill_vectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_skill_vectors_id_seq OWNED BY public.user_skill_vectors.id;


--
-- Name: user_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_skills (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    skill_id bigint NOT NULL,
    direction character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    weight double precision,
    source character varying DEFAULT 'manual'::character varying NOT NULL,
    proficiency_level character varying,
    note text,
    evidence_url character varying
);


--
-- Name: user_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_skills_id_seq OWNED BY public.user_skills.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    bio text,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying,
    name character varying,
    password_digest character varying,
    role character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    is_online boolean DEFAULT false,
    provider character varying,
    uid character varying,
    avatar_url character varying,
    github_token character varying,
    github_username character varying,
    github_repos_etag character varying,
    skills_last_scanned_at timestamp(6) without time zone,
    terms_accepted_at timestamp(6) without time zone,
    teaching_format character varying,
    availability_note character varying,
    average_rating double precision,
    ratings_count integer DEFAULT 0 NOT NULL,
    last_seen_at timestamp(6) without time zone,
    protected_from_moderation boolean DEFAULT false NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warnings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    issued_by_id bigint NOT NULL,
    reason text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: warnings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warnings_id_seq OWNED BY public.warnings.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: admin_broadcast_dismissals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcast_dismissals ALTER COLUMN id SET DEFAULT nextval('public.admin_broadcast_dismissals_id_seq'::regclass);


--
-- Name: admin_broadcasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcasts ALTER COLUMN id SET DEFAULT nextval('public.admin_broadcasts_id_seq'::regclass);


--
-- Name: banned_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_accounts ALTER COLUMN id SET DEFAULT nextval('public.banned_accounts_id_seq'::regclass);


--
-- Name: blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks ALTER COLUMN id SET DEFAULT nextval('public.blocks_id_seq'::regclass);


--
-- Name: chat_rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms ALTER COLUMN id SET DEFAULT nextval('public.chat_rooms_id_seq'::regclass);


--
-- Name: comment_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reactions ALTER COLUMN id SET DEFAULT nextval('public.comment_reactions_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: complaints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints ALTER COLUMN id SET DEFAULT nextval('public.complaints_id_seq'::regclass);


--
-- Name: dashboard_widgets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_widgets ALTER COLUMN id SET DEFAULT nextval('public.dashboard_widgets_id_seq'::regclass);


--
-- Name: dismissed_conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dismissed_conversations ALTER COLUMN id SET DEFAULT nextval('public.dismissed_conversations_id_seq'::regclass);


--
-- Name: escalations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations ALTER COLUMN id SET DEFAULT nextval('public.escalations_id_seq'::regclass);


--
-- Name: feed_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feed_preferences ALTER COLUMN id SET DEFAULT nextval('public.feed_preferences_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows ALTER COLUMN id SET DEFAULT nextval('public.follows_id_seq'::regclass);


--
-- Name: github_repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repositories ALTER COLUMN id SET DEFAULT nextval('public.github_repositories_id_seq'::regclass);


--
-- Name: likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes ALTER COLUMN id SET DEFAULT nextval('public.likes_id_seq'::regclass);


--
-- Name: match_digests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_digests ALTER COLUMN id SET DEFAULT nextval('public.match_digests_id_seq'::regclass);


--
-- Name: message_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions ALTER COLUMN id SET DEFAULT nextval('public.message_reactions_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: mutes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes ALTER COLUMN id SET DEFAULT nextval('public.mutes_id_seq'::regclass);


--
-- Name: post_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_notifications ALTER COLUMN id SET DEFAULT nextval('public.post_notifications_id_seq'::regclass);


--
-- Name: post_shares id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_shares ALTER COLUMN id SET DEFAULT nextval('public.post_shares_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: profile_widgets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_widgets ALTER COLUMN id SET DEFAULT nextval('public.profile_widgets_id_seq'::regclass);


--
-- Name: ratings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id SET DEFAULT nextval('public.ratings_id_seq'::regclass);


--
-- Name: reposts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reposts ALTER COLUMN id SET DEFAULT nextval('public.reposts_id_seq'::regclass);


--
-- Name: saved_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_posts ALTER COLUMN id SET DEFAULT nextval('public.saved_posts_id_seq'::regclass);


--
-- Name: skill_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_aliases ALTER COLUMN id SET DEFAULT nextval('public.skill_aliases_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: user_skill_vectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skill_vectors ALTER COLUMN id SET DEFAULT nextval('public.user_skill_vectors_id_seq'::regclass);


--
-- Name: user_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skills ALTER COLUMN id SET DEFAULT nextval('public.user_skills_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: warnings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warnings ALTER COLUMN id SET DEFAULT nextval('public.warnings_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: admin_broadcast_dismissals admin_broadcast_dismissals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcast_dismissals
    ADD CONSTRAINT admin_broadcast_dismissals_pkey PRIMARY KEY (id);


--
-- Name: admin_broadcasts admin_broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcasts
    ADD CONSTRAINT admin_broadcasts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: banned_accounts banned_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_accounts
    ADD CONSTRAINT banned_accounts_pkey PRIMARY KEY (id);


--
-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (id);


--
-- Name: chat_rooms chat_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_pkey PRIMARY KEY (id);


--
-- Name: comment_reactions comment_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (id);


--
-- Name: dashboard_widgets dashboard_widgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_widgets
    ADD CONSTRAINT dashboard_widgets_pkey PRIMARY KEY (id);


--
-- Name: dismissed_conversations dismissed_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dismissed_conversations
    ADD CONSTRAINT dismissed_conversations_pkey PRIMARY KEY (id);


--
-- Name: escalations escalations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT escalations_pkey PRIMARY KEY (id);


--
-- Name: feed_preferences feed_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feed_preferences
    ADD CONSTRAINT feed_preferences_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: github_repositories github_repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repositories
    ADD CONSTRAINT github_repositories_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: match_digests match_digests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_digests
    ADD CONSTRAINT match_digests_pkey PRIMARY KEY (id);


--
-- Name: message_reactions message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: mutes mutes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT mutes_pkey PRIMARY KEY (id);


--
-- Name: post_notifications post_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_notifications
    ADD CONSTRAINT post_notifications_pkey PRIMARY KEY (id);


--
-- Name: post_shares post_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_shares
    ADD CONSTRAINT post_shares_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: profile_widgets profile_widgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_widgets
    ADD CONSTRAINT profile_widgets_pkey PRIMARY KEY (id);


--
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- Name: reposts reposts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reposts
    ADD CONSTRAINT reposts_pkey PRIMARY KEY (id);


--
-- Name: saved_posts saved_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT saved_posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: skill_aliases skill_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_aliases
    ADD CONSTRAINT skill_aliases_pkey PRIMARY KEY (id);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: user_skill_vectors user_skill_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skill_vectors
    ADD CONSTRAINT user_skill_vectors_pkey PRIMARY KEY (id);


--
-- Name: user_skills user_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT user_skills_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: warnings warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warnings
    ADD CONSTRAINT warnings_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_admin_broadcast_dismissals_on_admin_broadcast_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_broadcast_dismissals_on_admin_broadcast_id ON public.admin_broadcast_dismissals USING btree (admin_broadcast_id);


--
-- Name: index_admin_broadcast_dismissals_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_broadcast_dismissals_on_user_id ON public.admin_broadcast_dismissals USING btree (user_id);


--
-- Name: index_admin_broadcasts_on_admin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_broadcasts_on_admin_id ON public.admin_broadcasts USING btree (admin_id);


--
-- Name: index_banned_accounts_on_banned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_banned_accounts_on_banned_by_id ON public.banned_accounts USING btree (banned_by_id);


--
-- Name: index_banned_accounts_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_banned_accounts_on_provider_and_uid ON public.banned_accounts USING btree (provider, uid);


--
-- Name: index_blocks_on_blocked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blocks_on_blocked_id ON public.blocks USING btree (blocked_id);


--
-- Name: index_blocks_on_blocker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blocks_on_blocker_id ON public.blocks USING btree (blocker_id);


--
-- Name: index_blocks_on_blocker_id_and_blocked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blocks_on_blocker_id_and_blocked_id ON public.blocks USING btree (blocker_id, blocked_id);


--
-- Name: index_broadcast_dismissals_on_user_and_broadcast; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_broadcast_dismissals_on_user_and_broadcast ON public.admin_broadcast_dismissals USING btree (user_id, admin_broadcast_id);


--
-- Name: index_chat_rooms_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_rooms_on_slug ON public.chat_rooms USING btree (slug);


--
-- Name: index_chat_rooms_on_user_a_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_rooms_on_user_a_id ON public.chat_rooms USING btree (user_a_id);


--
-- Name: index_chat_rooms_on_user_a_id_and_user_b_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_rooms_on_user_a_id_and_user_b_id ON public.chat_rooms USING btree (user_a_id, user_b_id);


--
-- Name: index_chat_rooms_on_user_b_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_rooms_on_user_b_id ON public.chat_rooms USING btree (user_b_id);


--
-- Name: index_comment_reactions_on_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_reactions_on_comment_id ON public.comment_reactions USING btree (comment_id);


--
-- Name: index_comment_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_reactions_on_user_id ON public.comment_reactions USING btree (user_id);


--
-- Name: index_comment_reactions_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_comment_reactions_uniqueness ON public.comment_reactions USING btree (user_id, comment_id, emoji);


--
-- Name: index_comments_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_parent_id ON public.comments USING btree (parent_id);


--
-- Name: index_comments_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_post_id ON public.comments USING btree (post_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_complaints_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_complaints_on_post_id ON public.complaints USING btree (post_id);


--
-- Name: index_complaints_on_reported_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_complaints_on_reported_by_id ON public.complaints USING btree (reported_by_id);


--
-- Name: index_complaints_on_target_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_complaints_on_target_user_id ON public.complaints USING btree (target_user_id);


--
-- Name: index_dashboard_widgets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboard_widgets_on_user_id ON public.dashboard_widgets USING btree (user_id);


--
-- Name: index_dashboard_widgets_on_user_id_and_widget_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dashboard_widgets_on_user_id_and_widget_type ON public.dashboard_widgets USING btree (user_id, widget_type);


--
-- Name: index_dismissed_conversations_on_chat_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dismissed_conversations_on_chat_room_id ON public.dismissed_conversations USING btree (chat_room_id);


--
-- Name: index_dismissed_conversations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dismissed_conversations_on_user_id ON public.dismissed_conversations USING btree (user_id);


--
-- Name: index_dismissed_conversations_on_user_id_and_chat_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dismissed_conversations_on_user_id_and_chat_room_id ON public.dismissed_conversations USING btree (user_id, chat_room_id);


--
-- Name: index_escalations_on_reported_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_escalations_on_reported_by_id ON public.escalations USING btree (reported_by_id);


--
-- Name: index_escalations_on_target_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_escalations_on_target_user_id ON public.escalations USING btree (target_user_id);


--
-- Name: index_feed_preferences_on_target_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feed_preferences_on_target_user_id ON public.feed_preferences USING btree (target_user_id);


--
-- Name: index_feed_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feed_preferences_on_user_id ON public.feed_preferences USING btree (user_id);


--
-- Name: index_feed_preferences_on_user_id_and_target_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feed_preferences_on_user_id_and_target_user_id ON public.feed_preferences USING btree (user_id, target_user_id);


--
-- Name: index_follows_on_followee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_followee_id ON public.follows USING btree (followee_id);


--
-- Name: index_follows_on_follower_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_follower_id ON public.follows USING btree (follower_id);


--
-- Name: index_follows_on_follower_id_and_followee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follows_on_follower_id_and_followee_id ON public.follows USING btree (follower_id, followee_id);


--
-- Name: index_github_repositories_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_github_repositories_on_user_id ON public.github_repositories USING btree (user_id);


--
-- Name: index_github_repositories_on_user_id_and_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_github_repositories_on_user_id_and_full_name ON public.github_repositories USING btree (user_id, full_name);


--
-- Name: index_likes_on_likeable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_likeable ON public.likes USING btree (likeable_type, likeable_id);


--
-- Name: index_likes_on_user_and_likeable; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_likes_on_user_and_likeable ON public.likes USING btree (user_id, likeable_type, likeable_id);


--
-- Name: index_likes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_user_id ON public.likes USING btree (user_id);


--
-- Name: index_match_digests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_match_digests_on_user_id ON public.match_digests USING btree (user_id);


--
-- Name: index_message_reactions_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_reactions_on_message_id ON public.message_reactions USING btree (message_id);


--
-- Name: index_message_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_reactions_on_user_id ON public.message_reactions USING btree (user_id);


--
-- Name: index_message_reactions_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_message_reactions_uniqueness ON public.message_reactions USING btree (user_id, message_id, emoji);


--
-- Name: index_messages_on_chat_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_room_id ON public.messages USING btree (chat_room_id);


--
-- Name: index_messages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_user_id ON public.messages USING btree (user_id);


--
-- Name: index_mutes_on_muted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mutes_on_muted_by_id ON public.mutes USING btree (muted_by_id);


--
-- Name: index_mutes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mutes_on_user_id ON public.mutes USING btree (user_id);


--
-- Name: index_post_notifications_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_notifications_on_post_id ON public.post_notifications USING btree (post_id);


--
-- Name: index_post_notifications_on_post_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_notifications_on_post_id_and_user_id ON public.post_notifications USING btree (post_id, user_id);


--
-- Name: index_post_notifications_on_skill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_notifications_on_skill_id ON public.post_notifications USING btree (skill_id);


--
-- Name: index_post_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_notifications_on_user_id ON public.post_notifications USING btree (user_id);


--
-- Name: index_post_shares_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_shares_on_post_id ON public.post_shares USING btree (post_id);


--
-- Name: index_post_shares_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_shares_on_recipient_id ON public.post_shares USING btree (recipient_id);


--
-- Name: index_post_shares_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_shares_on_user_id ON public.post_shares USING btree (user_id);


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);


--
-- Name: index_posts_skills_on_post_id_and_skill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_posts_skills_on_post_id_and_skill_id ON public.posts_skills USING btree (post_id, skill_id);


--
-- Name: index_profile_widgets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profile_widgets_on_user_id ON public.profile_widgets USING btree (user_id);


--
-- Name: index_profile_widgets_on_user_id_and_widget_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profile_widgets_on_user_id_and_widget_type ON public.profile_widgets USING btree (user_id, widget_type);


--
-- Name: index_ratings_on_chat_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ratings_on_chat_room_id ON public.ratings USING btree (chat_room_id);


--
-- Name: index_ratings_on_chat_room_id_and_rater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ratings_on_chat_room_id_and_rater_id ON public.ratings USING btree (chat_room_id, rater_id);


--
-- Name: index_ratings_on_rated_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ratings_on_rated_user_id ON public.ratings USING btree (rated_user_id);


--
-- Name: index_ratings_on_rater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ratings_on_rater_id ON public.ratings USING btree (rater_id);


--
-- Name: index_reposts_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reposts_on_post_id ON public.reposts USING btree (post_id);


--
-- Name: index_reposts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reposts_on_user_id ON public.reposts USING btree (user_id);


--
-- Name: index_reposts_on_user_id_and_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reposts_on_user_id_and_post_id ON public.reposts USING btree (user_id, post_id);


--
-- Name: index_saved_posts_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_posts_on_post_id ON public.saved_posts USING btree (post_id);


--
-- Name: index_saved_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_posts_on_user_id ON public.saved_posts USING btree (user_id);


--
-- Name: index_saved_posts_on_user_id_and_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_saved_posts_on_user_id_and_post_id ON public.saved_posts USING btree (user_id, post_id);


--
-- Name: index_skill_aliases_on_alias_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_skill_aliases_on_alias_name ON public.skill_aliases USING btree (alias_name);


--
-- Name: index_skill_aliases_on_skill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_skill_aliases_on_skill_id ON public.skill_aliases USING btree (skill_id);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_user_skill_vectors_on_embedding_learn_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_skill_vectors_on_embedding_learn_hnsw ON public.user_skill_vectors USING hnsw (embedding_learn public.vector_cosine_ops);


--
-- Name: index_user_skill_vectors_on_embedding_teach_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_skill_vectors_on_embedding_teach_hnsw ON public.user_skill_vectors USING hnsw (embedding_teach public.vector_cosine_ops);


--
-- Name: index_user_skill_vectors_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_skill_vectors_on_user_id ON public.user_skill_vectors USING btree (user_id);


--
-- Name: index_user_skills_on_skill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_skills_on_skill_id ON public.user_skills USING btree (skill_id);


--
-- Name: index_user_skills_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_skills_on_user_id ON public.user_skills USING btree (user_id);


--
-- Name: index_user_skills_on_user_skill_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_skills_on_user_skill_source ON public.user_skills USING btree (user_id, skill_id, source);


--
-- Name: index_users_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_provider_and_uid ON public.users USING btree (provider, uid);


--
-- Name: index_warnings_on_issued_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warnings_on_issued_by_id ON public.warnings USING btree (issued_by_id);


--
-- Name: index_warnings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warnings_on_user_id ON public.warnings USING btree (user_id);


--
-- Name: messages fk_rails_00aac238e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_00aac238e8 FOREIGN KEY (chat_room_id) REFERENCES public.chat_rooms(id);


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: admin_broadcasts fk_rails_077f0916b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcasts
    ADD CONSTRAINT fk_rails_077f0916b9 FOREIGN KEY (admin_id) REFERENCES public.users(id);


--
-- Name: ratings fk_rails_09c5eacaf5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT fk_rails_09c5eacaf5 FOREIGN KEY (rater_id) REFERENCES public.users(id);


--
-- Name: saved_posts fk_rails_0ac65331e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT fk_rails_0ac65331e7 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: warnings fk_rails_0ce2053883; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warnings
    ADD CONSTRAINT fk_rails_0ce2053883 FOREIGN KEY (issued_by_id) REFERENCES public.users(id);


--
-- Name: post_notifications fk_rails_0dc44904b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_notifications
    ADD CONSTRAINT fk_rails_0dc44904b4 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: comment_reactions fk_rails_0ef85ee455; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT fk_rails_0ef85ee455 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: feed_preferences fk_rails_19aba92dd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feed_preferences
    ADD CONSTRAINT fk_rails_19aba92dd7 FOREIGN KEY (target_user_id) REFERENCES public.users(id);


--
-- Name: mutes fk_rails_1b23cbd7ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT fk_rails_1b23cbd7ee FOREIGN KEY (muted_by_id) REFERENCES public.users(id);


--
-- Name: likes fk_rails_1e09b5dabf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT fk_rails_1e09b5dabf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: skill_aliases fk_rails_21523805f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_aliases
    ADD CONSTRAINT fk_rails_21523805f1 FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: post_notifications fk_rails_2250ff2a34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_notifications
    ADD CONSTRAINT fk_rails_2250ff2a34 FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: escalations fk_rails_2c420f45d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT fk_rails_2c420f45d8 FOREIGN KEY (target_user_id) REFERENCES public.users(id);


--
-- Name: comments fk_rails_2fd19c0db7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_2fd19c0db7 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: banned_accounts fk_rails_3316fd08fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_accounts
    ADD CONSTRAINT fk_rails_3316fd08fd FOREIGN KEY (banned_by_id) REFERENCES public.users(id);


--
-- Name: escalations fk_rails_33b4289689; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT fk_rails_33b4289689 FOREIGN KEY (reported_by_id) REFERENCES public.users(id);


--
-- Name: admin_broadcast_dismissals fk_rails_36740df432; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcast_dismissals
    ADD CONSTRAINT fk_rails_36740df432 FOREIGN KEY (admin_broadcast_id) REFERENCES public.admin_broadcasts(id);


--
-- Name: dismissed_conversations fk_rails_37a5662c39; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dismissed_conversations
    ADD CONSTRAINT fk_rails_37a5662c39 FOREIGN KEY (chat_room_id) REFERENCES public.chat_rooms(id);


--
-- Name: post_shares fk_rails_387c74307b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_shares
    ADD CONSTRAINT fk_rails_387c74307b FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: post_shares fk_rails_3a8283e89b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_shares
    ADD CONSTRAINT fk_rails_3a8283e89b FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: ratings fk_rails_3ad0f4c59e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT fk_rails_3ad0f4c59e FOREIGN KEY (rated_user_id) REFERENCES public.users(id);


--
-- Name: message_reactions fk_rails_3dfa2c0484; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT fk_rails_3dfa2c0484 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: admin_broadcast_dismissals fk_rails_492ff715e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_broadcast_dismissals
    ADD CONSTRAINT fk_rails_492ff715e9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: feed_preferences fk_rails_4a0bb1a79e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feed_preferences
    ADD CONSTRAINT fk_rails_4a0bb1a79e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: user_skills fk_rails_59acb6e327; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT fk_rails_59acb6e327 FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: posts fk_rails_5b5ddfd518; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: post_shares fk_rails_5db309fbe6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_shares
    ADD CONSTRAINT fk_rails_5db309fbe6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: message_reactions fk_rails_5dbedfb0be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT fk_rails_5dbedfb0be FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: follows fk_rails_622d34a301; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_rails_622d34a301 FOREIGN KEY (follower_id) REFERENCES public.users(id);


--
-- Name: mutes fk_rails_68f0ae7448; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT fk_rails_68f0ae7448 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: comment_reactions fk_rails_7d76194a5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT fk_rails_7d76194a5f FOREIGN KEY (comment_id) REFERENCES public.comments(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: profile_widgets fk_rails_90f516e618; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_widgets
    ADD CONSTRAINT fk_rails_90f516e618 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: complaints fk_rails_93b2851fc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT fk_rails_93b2851fc6 FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE SET NULL;


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: follows fk_rails_a8faf414f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_rails_a8faf414f1 FOREIGN KEY (followee_id) REFERENCES public.users(id);


--
-- Name: dismissed_conversations fk_rails_ac765d6627; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dismissed_conversations
    ADD CONSTRAINT fk_rails_ac765d6627 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: saved_posts fk_rails_afdf46603a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT fk_rails_afdf46603a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: match_digests fk_rails_b000e15cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_digests
    ADD CONSTRAINT fk_rails_b000e15cfa FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ratings fk_rails_b4cd1aa049; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT fk_rails_b4cd1aa049 FOREIGN KEY (chat_room_id) REFERENCES public.chat_rooms(id);


--
-- Name: complaints fk_rails_b6c903df0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT fk_rails_b6c903df0b FOREIGN KEY (reported_by_id) REFERENCES public.users(id);


--
-- Name: warnings fk_rails_bec75fa2b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warnings
    ADD CONSTRAINT fk_rails_bec75fa2b8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: blocks fk_rails_c0ad31bb25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT fk_rails_c0ad31bb25 FOREIGN KEY (blocker_id) REFERENCES public.users(id);


--
-- Name: reposts fk_rails_c395f67885; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reposts
    ADD CONSTRAINT fk_rails_c395f67885 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: dashboard_widgets fk_rails_c7c9e5fbe5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_widgets
    ADD CONSTRAINT fk_rails_c7c9e5fbe5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: blocks fk_rails_c7fbc30382; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT fk_rails_c7fbc30382 FOREIGN KEY (blocked_id) REFERENCES public.users(id);


--
-- Name: user_skill_vectors fk_rails_ccbd3f88ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skill_vectors
    ADD CONSTRAINT fk_rails_ccbd3f88ae FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: chat_rooms fk_rails_d5586dabb5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT fk_rails_d5586dabb5 FOREIGN KEY (user_b_id) REFERENCES public.users(id);


--
-- Name: complaints fk_rails_de62a326d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT fk_rails_de62a326d1 FOREIGN KEY (target_user_id) REFERENCES public.users(id);


--
-- Name: chat_rooms fk_rails_e6646af262; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT fk_rails_e6646af262 FOREIGN KEY (user_a_id) REFERENCES public.users(id);


--
-- Name: reposts fk_rails_e9f75e0f73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reposts
    ADD CONSTRAINT fk_rails_e9f75e0f73 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_notifications fk_rails_ed97168cf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_notifications
    ADD CONSTRAINT fk_rails_ed97168cf1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: github_repositories fk_rails_f54059a666; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repositories
    ADD CONSTRAINT fk_rails_f54059a666 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_skills fk_rails_fe61b6a893; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT fk_rails_fe61b6a893 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260720120000'),
('20260719223000'),
('20260719190003'),
('20260719190002'),
('20260719190001'),
('20260719190000'),
('20260719181500'),
('20260719180000'),
('20260719132000'),
('20260719000000'),
('20260718210000'),
('20260718201001'),
('20260718201000'),
('20260718200004'),
('20260718200003'),
('20260718200002'),
('20260718200001'),
('20260718200000'),
('20260718190005'),
('20260718190004'),
('20260718190003'),
('20260718190002'),
('20260718190001'),
('20260718190000'),
('20260718180000'),
('20260718170000'),
('20260718160001'),
('20260718160000'),
('20260718150000'),
('20260718140004'),
('20260718140003'),
('20260718140002'),
('20260718140001'),
('20260718140000'),
('20260718130002'),
('20260718130001'),
('20260718130000'),
('20260718120001'),
('20260718120000'),
('20260718110000'),
('20260718100001'),
('20260718100000'),
('20260717223700'),
('20260717210000'),
('20260717200000'),
('20260717130000'),
('20260717120000'),
('20260716150000'),
('20260716140000'),
('20260716130000'),
('20260716120000'),
('20260715000000'),
('20260714215056'),
('20260714210033'),
('20260714134326'),
('20260714131057'),
('20260714123954'),
('20260706080050'),
('20260706074618'),
('20260706070323'),
('20260704230941'),
('20260704230811'),
('20260704120504'),
('20260704120456'),
('1');

