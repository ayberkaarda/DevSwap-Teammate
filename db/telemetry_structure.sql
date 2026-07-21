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

SET default_tablespace = '';

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    action_type character varying NOT NULL,
    detail text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
)
PARTITION BY RANGE (created_at);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


SET default_table_access_method = heap;

--
-- Name: activity_logs_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs_2026_07 (
    id bigint DEFAULT nextval('public.activity_logs_id_seq'::regclass) CONSTRAINT activity_logs_id_not_null NOT NULL,
    user_id bigint CONSTRAINT activity_logs_user_id_not_null NOT NULL,
    action_type character varying CONSTRAINT activity_logs_action_type_not_null NOT NULL,
    detail text,
    metadata jsonb DEFAULT '{}'::jsonb CONSTRAINT activity_logs_metadata_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT activity_logs_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT activity_logs_updated_at_not_null NOT NULL
);


--
-- Name: activity_logs_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs_2026_08 (
    id bigint DEFAULT nextval('public.activity_logs_id_seq'::regclass) CONSTRAINT activity_logs_id_not_null NOT NULL,
    user_id bigint CONSTRAINT activity_logs_user_id_not_null NOT NULL,
    action_type character varying CONSTRAINT activity_logs_action_type_not_null NOT NULL,
    detail text,
    metadata jsonb DEFAULT '{}'::jsonb CONSTRAINT activity_logs_metadata_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT activity_logs_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT activity_logs_updated_at_not_null NOT NULL
);


--
-- Name: activity_logs_2026_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs_2026_09 (
    id bigint DEFAULT nextval('public.activity_logs_id_seq'::regclass) CONSTRAINT activity_logs_id_not_null NOT NULL,
    user_id bigint CONSTRAINT activity_logs_user_id_not_null NOT NULL,
    action_type character varying CONSTRAINT activity_logs_action_type_not_null NOT NULL,
    detail text,
    metadata jsonb DEFAULT '{}'::jsonb CONSTRAINT activity_logs_metadata_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT activity_logs_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT activity_logs_updated_at_not_null NOT NULL
);


--
-- Name: activity_logs_2026_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs_2026_10 (
    id bigint DEFAULT nextval('public.activity_logs_id_seq'::regclass) CONSTRAINT activity_logs_id_not_null NOT NULL,
    user_id bigint CONSTRAINT activity_logs_user_id_not_null NOT NULL,
    action_type character varying CONSTRAINT activity_logs_action_type_not_null NOT NULL,
    detail text,
    metadata jsonb DEFAULT '{}'::jsonb CONSTRAINT activity_logs_metadata_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT activity_logs_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT activity_logs_updated_at_not_null NOT NULL
);


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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: telemetry_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry_snapshots (
    id bigint NOT NULL,
    active_queue_jobs integer DEFAULT 0 NOT NULL,
    captured_at timestamp(6) without time zone NOT NULL,
    embeddings_generated_last_hour integer DEFAULT 0 NOT NULL,
    failed_queue_jobs integer DEFAULT 0 NOT NULL,
    github_scans_last_hour integer DEFAULT 0 NOT NULL,
    messages_per_minute integer DEFAULT 0 NOT NULL,
    online_users_count integer DEFAULT 0 NOT NULL,
    top_skills jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
)
PARTITION BY RANGE (captured_at);


--
-- Name: telemetry_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.telemetry_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: telemetry_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.telemetry_snapshots_id_seq OWNED BY public.telemetry_snapshots.id;


--
-- Name: telemetry_snapshots_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry_snapshots_2026_07 (
    id bigint DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass) CONSTRAINT telemetry_snapshots_id_not_null NOT NULL,
    active_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_active_queue_jobs_not_null NOT NULL,
    captured_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_captured_at_not_null NOT NULL,
    embeddings_generated_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_embeddings_generated_last_hour_not_null NOT NULL,
    failed_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_failed_queue_jobs_not_null NOT NULL,
    github_scans_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_github_scans_last_hour_not_null NOT NULL,
    messages_per_minute integer DEFAULT 0 CONSTRAINT telemetry_snapshots_messages_per_minute_not_null NOT NULL,
    online_users_count integer DEFAULT 0 CONSTRAINT telemetry_snapshots_online_users_count_not_null NOT NULL,
    top_skills jsonb DEFAULT '[]'::jsonb CONSTRAINT telemetry_snapshots_top_skills_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_updated_at_not_null NOT NULL
);


--
-- Name: telemetry_snapshots_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry_snapshots_2026_08 (
    id bigint DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass) CONSTRAINT telemetry_snapshots_id_not_null NOT NULL,
    active_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_active_queue_jobs_not_null NOT NULL,
    captured_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_captured_at_not_null NOT NULL,
    embeddings_generated_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_embeddings_generated_last_hour_not_null NOT NULL,
    failed_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_failed_queue_jobs_not_null NOT NULL,
    github_scans_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_github_scans_last_hour_not_null NOT NULL,
    messages_per_minute integer DEFAULT 0 CONSTRAINT telemetry_snapshots_messages_per_minute_not_null NOT NULL,
    online_users_count integer DEFAULT 0 CONSTRAINT telemetry_snapshots_online_users_count_not_null NOT NULL,
    top_skills jsonb DEFAULT '[]'::jsonb CONSTRAINT telemetry_snapshots_top_skills_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_updated_at_not_null NOT NULL
);


--
-- Name: telemetry_snapshots_2026_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry_snapshots_2026_09 (
    id bigint DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass) CONSTRAINT telemetry_snapshots_id_not_null NOT NULL,
    active_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_active_queue_jobs_not_null NOT NULL,
    captured_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_captured_at_not_null NOT NULL,
    embeddings_generated_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_embeddings_generated_last_hour_not_null NOT NULL,
    failed_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_failed_queue_jobs_not_null NOT NULL,
    github_scans_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_github_scans_last_hour_not_null NOT NULL,
    messages_per_minute integer DEFAULT 0 CONSTRAINT telemetry_snapshots_messages_per_minute_not_null NOT NULL,
    online_users_count integer DEFAULT 0 CONSTRAINT telemetry_snapshots_online_users_count_not_null NOT NULL,
    top_skills jsonb DEFAULT '[]'::jsonb CONSTRAINT telemetry_snapshots_top_skills_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_updated_at_not_null NOT NULL
);


--
-- Name: telemetry_snapshots_2026_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry_snapshots_2026_10 (
    id bigint DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass) CONSTRAINT telemetry_snapshots_id_not_null NOT NULL,
    active_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_active_queue_jobs_not_null NOT NULL,
    captured_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_captured_at_not_null NOT NULL,
    embeddings_generated_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_embeddings_generated_last_hour_not_null NOT NULL,
    failed_queue_jobs integer DEFAULT 0 CONSTRAINT telemetry_snapshots_failed_queue_jobs_not_null NOT NULL,
    github_scans_last_hour integer DEFAULT 0 CONSTRAINT telemetry_snapshots_github_scans_last_hour_not_null NOT NULL,
    messages_per_minute integer DEFAULT 0 CONSTRAINT telemetry_snapshots_messages_per_minute_not_null NOT NULL,
    online_users_count integer DEFAULT 0 CONSTRAINT telemetry_snapshots_online_users_count_not_null NOT NULL,
    top_skills jsonb DEFAULT '[]'::jsonb CONSTRAINT telemetry_snapshots_top_skills_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT telemetry_snapshots_updated_at_not_null NOT NULL
);


--
-- Name: activity_logs_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ATTACH PARTITION public.activity_logs_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00') TO ('2026-08-01 00:00:00');


--
-- Name: activity_logs_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ATTACH PARTITION public.activity_logs_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00') TO ('2026-09-01 00:00:00');


--
-- Name: activity_logs_2026_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ATTACH PARTITION public.activity_logs_2026_09 FOR VALUES FROM ('2026-09-01 00:00:00') TO ('2026-10-01 00:00:00');


--
-- Name: activity_logs_2026_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ATTACH PARTITION public.activity_logs_2026_10 FOR VALUES FROM ('2026-10-01 00:00:00') TO ('2026-11-01 00:00:00');


--
-- Name: telemetry_snapshots_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots ATTACH PARTITION public.telemetry_snapshots_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00') TO ('2026-08-01 00:00:00');


--
-- Name: telemetry_snapshots_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots ATTACH PARTITION public.telemetry_snapshots_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00') TO ('2026-09-01 00:00:00');


--
-- Name: telemetry_snapshots_2026_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots ATTACH PARTITION public.telemetry_snapshots_2026_09 FOR VALUES FROM ('2026-09-01 00:00:00') TO ('2026-10-01 00:00:00');


--
-- Name: telemetry_snapshots_2026_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots ATTACH PARTITION public.telemetry_snapshots_2026_10 FOR VALUES FROM ('2026-10-01 00:00:00') TO ('2026-11-01 00:00:00');


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: telemetry_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots ALTER COLUMN id SET DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id, created_at);


--
-- Name: activity_logs_2026_07 activity_logs_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs_2026_07
    ADD CONSTRAINT activity_logs_2026_07_pkey PRIMARY KEY (id, created_at);


--
-- Name: activity_logs_2026_08 activity_logs_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs_2026_08
    ADD CONSTRAINT activity_logs_2026_08_pkey PRIMARY KEY (id, created_at);


--
-- Name: activity_logs_2026_09 activity_logs_2026_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs_2026_09
    ADD CONSTRAINT activity_logs_2026_09_pkey PRIMARY KEY (id, created_at);


--
-- Name: activity_logs_2026_10 activity_logs_2026_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs_2026_10
    ADD CONSTRAINT activity_logs_2026_10_pkey PRIMARY KEY (id, created_at);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: telemetry_snapshots telemetry_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots
    ADD CONSTRAINT telemetry_snapshots_pkey PRIMARY KEY (id, captured_at);


--
-- Name: telemetry_snapshots_2026_07 telemetry_snapshots_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots_2026_07
    ADD CONSTRAINT telemetry_snapshots_2026_07_pkey PRIMARY KEY (id, captured_at);


--
-- Name: telemetry_snapshots_2026_08 telemetry_snapshots_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots_2026_08
    ADD CONSTRAINT telemetry_snapshots_2026_08_pkey PRIMARY KEY (id, captured_at);


--
-- Name: telemetry_snapshots_2026_09 telemetry_snapshots_2026_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots_2026_09
    ADD CONSTRAINT telemetry_snapshots_2026_09_pkey PRIMARY KEY (id, captured_at);


--
-- Name: telemetry_snapshots_2026_10 telemetry_snapshots_2026_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry_snapshots_2026_10
    ADD CONSTRAINT telemetry_snapshots_2026_10_pkey PRIMARY KEY (id, captured_at);


--
-- Name: index_activity_logs_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_user_id_and_created_at ON ONLY public.activity_logs USING btree (user_id, created_at);


--
-- Name: activity_logs_2026_07_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_2026_07_user_id_created_at_idx ON public.activity_logs_2026_07 USING btree (user_id, created_at);


--
-- Name: activity_logs_2026_08_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_2026_08_user_id_created_at_idx ON public.activity_logs_2026_08 USING btree (user_id, created_at);


--
-- Name: activity_logs_2026_09_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_2026_09_user_id_created_at_idx ON public.activity_logs_2026_09 USING btree (user_id, created_at);


--
-- Name: activity_logs_2026_10_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_2026_10_user_id_created_at_idx ON public.activity_logs_2026_10 USING btree (user_id, created_at);


--
-- Name: index_telemetry_snapshots_on_captured_at_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_telemetry_snapshots_on_captured_at_brin ON ONLY public.telemetry_snapshots USING brin (captured_at);


--
-- Name: telemetry_snapshots_2026_07_captured_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX telemetry_snapshots_2026_07_captured_at_idx ON public.telemetry_snapshots_2026_07 USING brin (captured_at);


--
-- Name: telemetry_snapshots_2026_08_captured_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX telemetry_snapshots_2026_08_captured_at_idx ON public.telemetry_snapshots_2026_08 USING brin (captured_at);


--
-- Name: telemetry_snapshots_2026_09_captured_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX telemetry_snapshots_2026_09_captured_at_idx ON public.telemetry_snapshots_2026_09 USING brin (captured_at);


--
-- Name: telemetry_snapshots_2026_10_captured_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX telemetry_snapshots_2026_10_captured_at_idx ON public.telemetry_snapshots_2026_10 USING brin (captured_at);


--
-- Name: activity_logs_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activity_logs_pkey ATTACH PARTITION public.activity_logs_2026_07_pkey;


--
-- Name: activity_logs_2026_07_user_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activity_logs_on_user_id_and_created_at ATTACH PARTITION public.activity_logs_2026_07_user_id_created_at_idx;


--
-- Name: activity_logs_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activity_logs_pkey ATTACH PARTITION public.activity_logs_2026_08_pkey;


--
-- Name: activity_logs_2026_08_user_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activity_logs_on_user_id_and_created_at ATTACH PARTITION public.activity_logs_2026_08_user_id_created_at_idx;


--
-- Name: activity_logs_2026_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activity_logs_pkey ATTACH PARTITION public.activity_logs_2026_09_pkey;


--
-- Name: activity_logs_2026_09_user_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activity_logs_on_user_id_and_created_at ATTACH PARTITION public.activity_logs_2026_09_user_id_created_at_idx;


--
-- Name: activity_logs_2026_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activity_logs_pkey ATTACH PARTITION public.activity_logs_2026_10_pkey;


--
-- Name: activity_logs_2026_10_user_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activity_logs_on_user_id_and_created_at ATTACH PARTITION public.activity_logs_2026_10_user_id_created_at_idx;


--
-- Name: telemetry_snapshots_2026_07_captured_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_telemetry_snapshots_on_captured_at_brin ATTACH PARTITION public.telemetry_snapshots_2026_07_captured_at_idx;


--
-- Name: telemetry_snapshots_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.telemetry_snapshots_pkey ATTACH PARTITION public.telemetry_snapshots_2026_07_pkey;


--
-- Name: telemetry_snapshots_2026_08_captured_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_telemetry_snapshots_on_captured_at_brin ATTACH PARTITION public.telemetry_snapshots_2026_08_captured_at_idx;


--
-- Name: telemetry_snapshots_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.telemetry_snapshots_pkey ATTACH PARTITION public.telemetry_snapshots_2026_08_pkey;


--
-- Name: telemetry_snapshots_2026_09_captured_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_telemetry_snapshots_on_captured_at_brin ATTACH PARTITION public.telemetry_snapshots_2026_09_captured_at_idx;


--
-- Name: telemetry_snapshots_2026_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.telemetry_snapshots_pkey ATTACH PARTITION public.telemetry_snapshots_2026_09_pkey;


--
-- Name: telemetry_snapshots_2026_10_captured_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_telemetry_snapshots_on_captured_at_brin ATTACH PARTITION public.telemetry_snapshots_2026_10_captured_at_idx;


--
-- Name: telemetry_snapshots_2026_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.telemetry_snapshots_pkey ATTACH PARTITION public.telemetry_snapshots_2026_10_pkey;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260717210000');

